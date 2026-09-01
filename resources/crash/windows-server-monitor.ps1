param(
    [Parameter(Mandatory = $true)]
    [int]$TargetProcessId,
    [Parameter(Mandatory = $true)]
    [string]$DumpPath,
    [Parameter(Mandatory = $true)]
    [string]$EventPath,
    [Parameter(Mandatory = $true)]
    [uint32]$DumpType
)

$ErrorActionPreference = 'Stop'

$source = @'
using System;
using System.Globalization;
using System.IO;
using System.Runtime.InteropServices;
using Microsoft.Win32.SafeHandles;

public static class DigitalServerCrashMonitor
{
    private const uint EXCEPTION_DEBUG_EVENT = 1;
    private const uint CREATE_THREAD_DEBUG_EVENT = 2;
    private const uint CREATE_PROCESS_DEBUG_EVENT = 3;
    private const uint EXIT_PROCESS_DEBUG_EVENT = 5;
    private const uint LOAD_DLL_DEBUG_EVENT = 6;
    private const uint DBG_CONTINUE = 0x00010002;
    private const uint DBG_EXCEPTION_NOT_HANDLED = 0x80010001;
    private const uint STATUS_BREAKPOINT = 0x80000003;
    private const uint PROCESS_VM_READ = 0x0010;
    private const uint PROCESS_DUP_HANDLE = 0x0040;
    private const uint PROCESS_QUERY_INFORMATION = 0x0400;

    [DllImport("kernel32.dll", SetLastError = true)]
    private static extern bool DebugActiveProcess(uint processId);

    [DllImport("kernel32.dll", SetLastError = true)]
    private static extern bool DebugActiveProcessStop(uint processId);

    [DllImport("kernel32.dll", SetLastError = true)]
    private static extern bool DebugSetProcessKillOnExit(bool killOnExit);

    [DllImport("kernel32.dll", SetLastError = true)]
    private static extern bool WaitForDebugEvent(IntPtr debugEvent, uint milliseconds);

    [DllImport("kernel32.dll", SetLastError = true)]
    private static extern bool ContinueDebugEvent(
        uint processId,
        uint threadId,
        uint continueStatus
    );

    [DllImport("kernel32.dll", SetLastError = true)]
    private static extern IntPtr OpenProcess(uint desiredAccess, bool inheritHandle, uint processId);

    [DllImport("kernel32.dll", SetLastError = true)]
    private static extern bool CloseHandle(IntPtr handle);

    [DllImport("dbghelp.dll", SetLastError = true)]
    private static extern bool MiniDumpWriteDump(
        IntPtr process,
        uint processId,
        IntPtr file,
        uint dumpType,
        IntPtr exceptionParam,
        IntPtr userStreamParam,
        IntPtr callbackParam
    );

    public static int Run(uint processId, string dumpPath, string eventPath, uint dumpType)
    {
        IntPtr debugEvent = IntPtr.Zero;
        IntPtr process = IntPtr.Zero;
        bool attached = false;
        try
        {
            process = OpenProcess(
                PROCESS_VM_READ | PROCESS_DUP_HANDLE | PROCESS_QUERY_INFORMATION,
                false,
                processId
            );
            if (process == IntPtr.Zero)
                throw LastWin32("OpenProcess");

            if (!DebugActiveProcess(processId))
                throw LastWin32("DebugActiveProcess");
            attached = true;
            if (!DebugSetProcessKillOnExit(false))
                throw LastWin32("DebugSetProcessKillOnExit");

            Console.Out.WriteLine("DIDE_CRASH_MONITOR_READY");
            Console.Out.Flush();

            // DEBUG_EVENT is 176 bytes on the x64 Windows target shipped by the extension.
            debugEvent = Marshal.AllocHGlobal(176);
            while (true)
            {
                Zero(debugEvent, 176);
                if (!WaitForDebugEvent(debugEvent, 1000))
                {
                    int error = Marshal.GetLastWin32Error();
                    if (error == 121)
                        continue;
                    throw new System.ComponentModel.Win32Exception(error, "WaitForDebugEvent failed");
                }

                uint eventCode = unchecked((uint)Marshal.ReadInt32(debugEvent, 0));
                uint eventProcessId = unchecked((uint)Marshal.ReadInt32(debugEvent, 4));
                uint eventThreadId = unchecked((uint)Marshal.ReadInt32(debugEvent, 8));
                uint continueStatus = DBG_CONTINUE;
                bool exitAfterContinue = false;

                if (eventCode == EXCEPTION_DEBUG_EVENT)
                {
                    uint exceptionCode = unchecked((uint)Marshal.ReadInt32(debugEvent, 16));
                    ulong exceptionAddress = unchecked((ulong)Marshal.ReadInt64(debugEvent, 32));
                    uint firstChance = unchecked((uint)Marshal.ReadInt32(debugEvent, 168));
                    if (firstChance == 0)
                    {
                        WriteDumpAndEvent(
                            process,
                            processId,
                            eventThreadId,
                            exceptionCode,
                            exceptionAddress,
                            dumpType,
                            dumpPath,
                            eventPath
                        );
                    }
                    continueStatus = firstChance != 0 && exceptionCode == STATUS_BREAKPOINT
                        ? DBG_CONTINUE
                        : DBG_EXCEPTION_NOT_HANDLED;
                }
                else if (eventCode == CREATE_THREAD_DEBUG_EVENT)
                {
                    CloseIfValid(Marshal.ReadIntPtr(debugEvent, 16));
                }
                else if (eventCode == CREATE_PROCESS_DEBUG_EVENT)
                {
                    CloseIfValid(Marshal.ReadIntPtr(debugEvent, 16));
                    CloseIfValid(Marshal.ReadIntPtr(debugEvent, 24));
                    CloseIfValid(Marshal.ReadIntPtr(debugEvent, 32));
                }
                else if (eventCode == LOAD_DLL_DEBUG_EVENT)
                {
                    CloseIfValid(Marshal.ReadIntPtr(debugEvent, 16));
                }
                else if (eventCode == EXIT_PROCESS_DEBUG_EVENT)
                {
                    exitAfterContinue = true;
                }

                if (!ContinueDebugEvent(eventProcessId, eventThreadId, continueStatus))
                    throw LastWin32("ContinueDebugEvent");
                if (exitAfterContinue)
                    break;
            }
            return 0;
        }
        catch (Exception error)
        {
            Console.Error.WriteLine(error.ToString());
            return 2;
        }
        finally
        {
            if (attached)
                DebugActiveProcessStop(processId);
            if (debugEvent != IntPtr.Zero)
                Marshal.FreeHGlobal(debugEvent);
            CloseIfValid(process);
        }
    }

    private static void WriteDumpAndEvent(
        IntPtr process,
        uint processId,
        uint threadId,
        uint exceptionCode,
        ulong exceptionAddress,
        uint dumpType,
        string dumpPath,
        string eventPath
    )
    {
        bool written = false;
        string error = null;
        try
        {
            string directory = Path.GetDirectoryName(dumpPath);
            if (!String.IsNullOrEmpty(directory))
                Directory.CreateDirectory(directory);
            using (FileStream dump = new FileStream(
                dumpPath,
                FileMode.Create,
                FileAccess.ReadWrite,
                FileShare.Read
            ))
            {
                written = MiniDumpWriteDump(
                    process,
                    processId,
                    dump.SafeFileHandle.DangerousGetHandle(),
                    dumpType,
                    IntPtr.Zero,
                    IntPtr.Zero,
                    IntPtr.Zero
                );
                if (!written)
                    error = LastWin32("MiniDumpWriteDump").Message;
                dump.Flush(true);
            }
        }
        catch (Exception dumpError)
        {
            error = dumpError.ToString();
        }

        string json = String.Format(
            CultureInfo.InvariantCulture,
            "{{\n  \"capturedAt\": \"{0}\",\n  \"processId\": {1},\n  \"threadId\": {2},\n  \"exceptionCode\": {3},\n  \"exceptionCodeHex\": \"0x{3:X8}\",\n  \"exceptionAddress\": {4},\n  \"exceptionAddressHex\": \"0x{4:X16}\",\n  \"firstChance\": false,\n  \"dumpType\": {5},\n  \"dumpWritten\": {6},\n  \"dumpError\": {7}\n}}\n",
            DateTime.UtcNow.ToString("o", CultureInfo.InvariantCulture),
            processId,
            threadId,
            exceptionCode,
            exceptionAddress,
            dumpType,
            written ? "true" : "false",
            error == null ? "null" : "\"" + JsonEscape(error) + "\""
        );
        File.WriteAllText(eventPath, json);
    }

    private static Exception LastWin32(string operation)
    {
        return new System.ComponentModel.Win32Exception(
            Marshal.GetLastWin32Error(),
            operation + " failed"
        );
    }

    private static string JsonEscape(string value)
    {
        return value
            .Replace("\\", "\\\\")
            .Replace("\"", "\\\"")
            .Replace("\r", "\\r")
            .Replace("\n", "\\n")
            .Replace("\t", "\\t");
    }

    private static void CloseIfValid(IntPtr handle)
    {
        if (handle != IntPtr.Zero && handle != new IntPtr(-1))
            CloseHandle(handle);
    }

    private static void Zero(IntPtr buffer, int length)
    {
        for (int offset = 0; offset < length; offset += 8)
            Marshal.WriteInt64(buffer, offset, 0);
    }
}
'@

Add-Type -TypeDefinition $source -Language CSharp
$result = [DigitalServerCrashMonitor]::Run(
    [uint32]$TargetProcessId,
    $DumpPath,
    $EventPath,
    $DumpType
)
exit $result
