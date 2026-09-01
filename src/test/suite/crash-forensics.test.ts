import * as assert from 'assert';
import * as fs from 'fs';
import * as path from 'path';
import {
    isWindowsAccessViolation,
    unsignedWindowsExitCode,
    windowsExitCodeHex,
} from '../../server/crashForensics';

suite('Digital Server crash forensics', () => {
    test('normalizes signed and unsigned Windows exception exit codes', () => {
        assert.strictEqual(unsignedWindowsExitCode(3221225477), 3221225477);
        assert.strictEqual(unsignedWindowsExitCode(-1073741819), 3221225477);
        assert.strictEqual(windowsExitCodeHex(3221225477), '0xC0000005');
        assert.strictEqual(windowsExitCodeHex(-1073741819), '0xC0000005');
        assert.ok(isWindowsAccessViolation(3221225477));
        assert.ok(isWindowsAccessViolation(-1073741819));
        assert.ok(!isWindowsAccessViolation(0));
    });

    test('packages the Windows debugger and exposes evidence commands', () => {
        const extensionRoot = path.resolve(__dirname, '..', '..', '..');
        const monitorPath = path.join(
            extensionRoot,
            'resources',
            'crash',
            'windows-server-monitor.ps1',
        );
        const monitor = fs.readFileSync(monitorPath, 'utf8');
        assert.match(monitor, /DebugActiveProcess/);
        assert.match(monitor, /WaitForDebugEvent/);
        assert.match(monitor, /MiniDumpWriteDump/);
        assert.match(monitor, /DIDE_CRASH_MONITOR_READY/);

        const manifest = JSON.parse(fs.readFileSync(
            path.join(extensionRoot, 'package.json'),
            'utf8',
        ));
        const commands = new Set(
            manifest.contributes.commands.map((entry: { command: string }) => entry.command),
        );
        assert.ok(commands.has('digital-ide.server.openCrashEvidence'));
        assert.ok(commands.has('digital-ide.server.exportCrashEvidence'));
        assert.strictEqual(
            manifest.scripts['package:win32-x64'],
            'npm run package:universal',
        );
        assert.strictEqual(
            manifest.scripts['package:linux-x64'],
            'npm run package:universal',
        );
        assert.ok(fs.existsSync(path.join(extensionRoot, 'scripts', 'package-universal.sh')));

        const source = fs.readFileSync(
            path.join(extensionRoot, 'src', 'server', 'crashForensics.ts'),
            'utf8',
        );
        assert.match(source, /Digital Server SHA-256/);
        assert.match(source, /Digital Server symbols SHA-256/);
    });
});
