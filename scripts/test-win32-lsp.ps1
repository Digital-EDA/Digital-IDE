param(
    [string]$Server = "",
    [switch]$SkipInstall
)

$ErrorActionPreference = "Stop"
if (-not $IsWindows -and $env:OS -ne "Windows_NT") {
    throw "test-win32-lsp.ps1 must run on Windows"
}

$ExtensionRoot = Split-Path -Parent $PSScriptRoot
$ServerRoot = (Resolve-Path (Join-Path $ExtensionRoot "../..")).Path
if ([string]::IsNullOrWhiteSpace($Server)) {
    $Server = Join-Path $ExtensionRoot "resources/server/win32/x64/digital-server.exe"
}
$Server = (Resolve-Path $Server).Path
$Workspace = (Resolve-Path (Join-Path $ExtensionRoot "test-fixtures/workspace")).Path
$VhdlLibrary = (Resolve-Path (Join-Path $ServerRoot "tests/vhdl/vhdl_libraries")).Path
$Smoke = (Resolve-Path (Join-Path $ServerRoot "tests/windows/lsp-runtime-smoke.mjs")).Path

Push-Location $ExtensionRoot
try {
    if (-not $SkipInstall) {
        npm ci --no-audit --no-fund
        if ($LASTEXITCODE -ne 0) { throw "npm ci failed" }
    }
    npm run compile
    if ($LASTEXITCODE -ne 0) { throw "TypeScript compilation failed" }

    node $Smoke `
        --server $Server `
        --workspace $Workspace `
        --systemverilog-document (Join-Path $Workspace "src/sv/child.sv") `
        --vhdl-document (Join-Path $Workspace "src/vhdl/top.vhd") `
        --vhdl-library $VhdlLibrary
    if ($LASTEXITCODE -ne 0) { throw "Windows backend LSP smoke failed" }

    $env:DIGITAL_SERVER_PATH = $Server
    $env:DIGITAL_SERVER_VHDL_LIBRARY_PATH = $VhdlLibrary
    node ./out/test/runTest.js --grep "SystemVerilog desktop LSP|VHDL desktop LSP"
    if ($LASTEXITCODE -ne 0) { throw "Windows Extension Host LSP suite failed" }
} finally {
    Pop-Location
}
