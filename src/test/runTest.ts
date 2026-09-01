import { ChildProcess, spawn, spawnSync } from 'child_process';
import * as fs from 'fs';
import * as net from 'net';
import * as path from 'path';
import { runTests } from '@vscode/test-electron';

async function reserveTcpPort(): Promise<number> {
    return new Promise((resolve, reject) => {
        const server = net.createServer();
        server.once('error', reject);
        server.listen(0, '127.0.0.1', () => {
            const address = server.address();
            if (!address || typeof address === 'string') {
                server.close();
                reject(new Error('Failed to reserve a renderer debugging port'));
                return;
            }
            server.close(error => error ? reject(error) : resolve(address.port));
        });
    });
}

function runUnderXvfb(): never {
    const env: NodeJS.ProcessEnv = { ...process.env, DIGITAL_VSCODE_TEST_XVFB: '1' };
    delete env.ELECTRON_RUN_AS_NODE;
    const result = spawnSync(
        'xvfb-run',
        ['-a', process.execPath, __filename, ...process.argv.slice(2)],
        {
            env,
            stdio: 'inherit',
        },
    );
    process.exit(result.status ?? 1);
}

function commandLineOption(name: string): string | undefined {
    const index = process.argv.indexOf(name);
    if (index < 0) {
        return undefined;
    }
    const value = process.argv[index + 1];
    if (!value || value.startsWith('--')) {
        throw new Error(`${name} requires a non-empty value`);
    }
    return value;
}

async function main(): Promise<void> {
    if (process.platform === 'linux' && !process.env.DISPLAY && !process.env.DIGITAL_VSCODE_TEST_XVFB) {
        runUnderXvfb();
    }

    if (process.env.DIGITAL_TOOLCHAIN_E2E_MODE === 'xilinx-ps-board') {
        for (const variable of ['DIDE_VIVADO_COMMAND', 'DIDE_XSCT_COMMAND']) {
            if (!process.env[variable]?.trim()) {
                throw new Error(`${variable} is required for Xilinx PS board signoff`);
            }
        }
    }

    const extensionDevelopmentPath = path.resolve(__dirname, '..', '..');
    const extensionTestsPath = path.resolve(__dirname, 'suite', 'index');
    const requestedGrep = commandLineOption('--grep');
    const fixturePath = path.join(extensionDevelopmentPath, 'test-fixtures', 'workspace');
    const serverRoot = path.resolve(extensionDevelopmentPath, '..');
    const simulationRoot = path.resolve(
        serverRoot,
        '..',
        '..',
        'project',
        'simulation',
        'digital-server',
    );
    fs.mkdirSync(simulationRoot, { recursive: true });
    const temporaryRoot = fs.mkdtempSync(path.join(simulationRoot, 'vscode-electron-'));
    const workspacePath = path.join(temporaryRoot, 'workspace');
    const secondaryWorkspacePath = path.join(temporaryRoot, 'secondary-workspace');
    const cancellationWorkspacePath = path.join(temporaryRoot, 'cancellation-workspace');
    const fakeEfinityPackage = path.join(temporaryRoot, 'fake-efinity');
    const fakeVivado = path.join(temporaryRoot, 'fake-vivado');
    const fakeVivadoLaunches = path.join(temporaryRoot, 'fake-vivado.launches');
    const fakeVivadoRequests = path.join(temporaryRoot, 'fake-vivado.requests');
    const fakeVivadoSleep = path.join(temporaryRoot, 'fake-vivado-sleep');
    const fakeVivadoSleepStarted = path.join(temporaryRoot, 'fake-vivado-sleep.started');
    const fakeVivadoToolchainStarted = path.join(
        temporaryRoot,
        'fake-vivado-toolchain.started',
    );
    const waveServerReady = path.join(temporaryRoot, 'wave-server.port');
    const waveCapture = path.join(temporaryRoot, 'wave-capture.json');
    const vendorSimulationWorkspacePath = path.join(
        temporaryRoot,
        'vendor-simulation-workspace',
    );
    const workspaceFilePath = path.join(temporaryRoot, 'digital-ide.code-workspace');
    const userDataPath = path.join(temporaryRoot, 'user-data');
    const extensionsPath = path.join(temporaryRoot, 'extensions');
    fs.cpSync(fixturePath, workspacePath, { recursive: true });
    const softwareDataPath = path.join(workspacePath, 'software', 'data');
    fs.mkdirSync(softwareDataPath, { recursive: true });
    const hdfFixture = path.join(
        serverRoot,
        'tests',
        'project',
        'xilinx',
        'soc',
        'ZynqA9',
        'user',
        'sdk',
        'data',
        'base.hdf',
    );
    if (fs.existsSync(hdfFixture)) {
        fs.copyFileSync(hdfFixture, path.join(softwareDataPath, 'lsp-test.hdf'));
    } else if (requestedGrep !== 'Netlist Webview integration') {
        throw new Error(`Required Xilinx HDF test fixture does not exist: ${hdfFixture}`);
    }
    const debuggerOutput = path.join(workspacePath, 'project', 'debugger');
    fs.mkdirSync(debuggerOutput, { recursive: true });
    fs.writeFileSync(path.join(debuggerOutput, 'conditions.json'), '[]');
    fs.writeFileSync(path.join(debuggerOutput, 'top.hex'), 'bitstream');
    fs.writeFileSync(
        path.join(debuggerOutput, 'debug_manifest.json'),
        JSON.stringify({
            version: 1,
            top: 'electron_debug_top',
            vendor: 'efinity',
            config_path: path.join(workspacePath, 'data', 'electron_debug_top.debug.toml'),
            ila: [],
            vio: [],
            cascades: [],
            hardware_hash: 'electron-debug-hardware',
        }, null, 2),
    );
    fs.writeFileSync(
        path.join(debuggerOutput, 'debugstamp.json'),
        JSON.stringify({
            version: 2,
            vendor: 'efinity',
            toolVersion: '2026.1-electron-fixture',
            device: 'Ti60F100S3F2',
            top: 'electron_debug_top',
            hardwareHash: 'electron-debug-hardware',
            rtlHash: 'electron-debug-rtl',
            projectHash: 'electron-debug-project',
            bitstreamHash: 'electron-debug-bitstream',
            artifacts: [{
                kind: 'bitstream',
                path: 'project/debugger/top.hex',
                hash: '1ad145615b37d6d5d3f408e029ab0c30895d265091b1e42192bb036bdc04b24c',
            }],
            connection: {
                backend: 'efinity',
                jtagFamily: 'titanium',
                jtagUser: 1,
                instructionWidth: 5,
                instructionValue: 8,
                conditionsHash: 'd53d18c23212ea7b6300594bb89bce60218f6eff2b9d628b8cc42d3e79bbd5ab',
            },
        }, null, 2),
    );
    const vivadoDebuggerOutput = path.join(workspacePath, 'project', 'vivado-debugger');
    fs.mkdirSync(vivadoDebuggerOutput, { recursive: true });
    fs.writeFileSync(path.join(vivadoDebuggerOutput, 'conditions.tcl'), '[]');
    fs.writeFileSync(path.join(vivadoDebuggerOutput, 'top.bit'), 'bitstream');
    fs.writeFileSync(path.join(vivadoDebuggerOutput, 'top.ltx'), 'bitstream');
    const vivadoProbe = (name: string, width: number, probeType: string) => ({
        name,
        debug_path: null,
        width,
        probe_type: probeType,
        probe_mode: 'data_and_trigger',
        direction: null,
        init_val: '0',
    });
    const vivadoVioProbe = (
        name: string,
        width: number,
        direction: 'in' | 'out' | null,
        initVal = 0,
    ) => ({
        ...vivadoProbe(name, width, direction === null ? 'clock' : 'data'),
        direction,
        init_val: String(initVal),
    });
    fs.writeFileSync(
        path.join(vivadoDebuggerOutput, 'debug_manifest.json'),
        JSON.stringify({
            version: 1,
            top: 'electron_vivado_top',
            vendor: 'vivado',
            config_path: path.join(workspacePath, 'data', 'electron_vivado_top.debug.toml'),
            ila: [{
                id: 0,
                label: 'desktop_capture',
                module_id: 0,
                uuid: 'desktop-logical-uuid',
                data_depth: 1024,
                pipe_stages: 1,
                clock: vivadoProbe('clk', 1, 'clock'),
                probes: [
                    vivadoProbe('counter', 8, 'data'),
                    vivadoProbe('valid', 1, 'data'),
                ],
                capture_condition: null,
                trigger_condition: null,
            }],
            vio: [{
                id: 0,
                label: 'desktop_control',
                module_id: 1,
                uuid: 'desktop-logical-vio-uuid',
                clock: vivadoVioProbe('clk', 1, null),
                inputs: [vivadoVioProbe('status', 4, 'in')],
                outputs: [vivadoVioProbe('control', 4, 'out', 5)],
                input_activity: true,
            }],
            cascades: [],
            hardware_hash: 'electron-vivado-hardware',
        }, null, 2),
    );
    fs.writeFileSync(
        path.join(vivadoDebuggerOutput, 'debugstamp.json'),
        JSON.stringify({
            version: 2,
            vendor: 'vivado',
            toolVersion: 'Vivado v2022.2 desktop fixture',
            device: 'xc7a35tftg256-1',
            top: 'electron_vivado_top',
            hardwareHash: 'electron-vivado-hardware',
            rtlHash: 'electron-vivado-rtl',
            projectHash: 'electron-vivado-project',
            bitstreamHash: 'electron-vivado-build',
            artifacts: [
                {
                    kind: 'bitstream',
                    path: 'project/vivado-debugger/top.bit',
                    hash: '1ad145615b37d6d5d3f408e029ab0c30895d265091b1e42192bb036bdc04b24c',
                },
                {
                    kind: 'probes',
                    path: 'project/vivado-debugger/top.ltx',
                    hash: '1ad145615b37d6d5d3f408e029ab0c30895d265091b1e42192bb036bdc04b24c',
                },
                {
                    kind: 'conditions',
                    path: 'project/vivado-debugger/conditions.tcl',
                    hash: 'd53d18c23212ea7b6300594bb89bce60218f6eff2b9d628b8cc42d3e79bbd5ab',
                },
            ],
            connection: {
                backend: 'vivado',
                probesHash: '1ad145615b37d6d5d3f408e029ab0c30895d265091b1e42192bb036bdc04b24c',
                conditionsHash: 'd53d18c23212ea7b6300594bb89bce60218f6eff2b9d628b8cc42d3e79bbd5ab',
                coreUuids: {
                    'ila:0': '00112233445566778899aabbccddeeff',
                    'vio:0': 'ffeeddccbbaa99887766554433221100',
                },
            },
        }, null, 2),
    );
    fs.writeFileSync(
        fakeVivado,
        `#!/usr/bin/python3.10
import os
import re
import sys
import time

with open(${JSON.stringify(fakeVivadoLaunches)}, 'a', encoding='utf-8') as stream:
    stream.write(str(os.getpid()) + '\\n')

vio_value = 5
buffer = []
for line in sys.stdin:
    buffer.append(line)
    if line.strip() != 'flush stdout':
        continue
    request = ''.join(buffer)
    buffer = []
    request_id = re.search(r'__DIDE_BEGIN__:(\\d+)', request).group(1)
    with open(${JSON.stringify(fakeVivadoRequests)}, 'a', encoding='utf-8') as stream:
        stream.write(request_id + '\\n')
    if 'launch_runs synth_1' in request:
        with open(${JSON.stringify(fakeVivadoToolchainStarted)}, 'w', encoding='utf-8') as stream:
            stream.write('started')
        print('digital-server-electron-cancel-started')
        sys.stdout.flush()
        time.sleep(30)
    typed = []
    if 'write_hw_ila_data' in request:
        payload = re.search(r'-csv_file "([^\\"]+)"', request).group(1)
        with open(payload, 'w', encoding='utf-8') as stream:
            stream.write('Radix - 2,,,Hex,Hex\\n')
            stream.write('Sample in Buffer,Sample in Window,TRIGGER,dide_ila_0/probe0,dide_ila_0/probe1\\n')
            stream.write('0,0,0,0a,1\\n1,1,0,ff,0\\n')
        typed.append('digital_server_debugger_capture:0')
        typed.append('digital_server_debugger_capture_timing:25:40:50:60')
    elif 'digital_server_debugger_status:' in request:
        typed.append('digital_server_debugger_status:7265616479:17')
    output = re.search(r'set_property OUTPUT_VALUE "([0-9a-fA-F]+)" \\$__dide_vio_output_0', request)
    if output:
        vio_value = int(output.group(1), 16)
    if 'digital_server_debugger_vio_output:0' in request:
        value = ('0b' + format(vio_value, '04b')).encode().hex()
        typed.append('digital_server_debugger_vio_output:0:' + value)
    if 'digital_server_debugger_vio_input:0' in request:
        value = ('0b' + format(vio_value, '04b')).encode().hex()
        typed.append('digital_server_debugger_vio_input:0:' + value)
    print('__DIDE_BEGIN__:' + request_id)
    for record in typed:
        print(record)
    print('__DIDE_MSG__:' + request_id + ':')
    print('__DIDE_RC__:' + request_id + ':0')
    print('__DIDE_END__:' + request_id)
    sys.stdout.flush()
`,
    );
    fs.writeFileSync(
        fakeVivadoSleep,
        `#!/usr/bin/python3.10
import re
import sys
import time

buffer = []
for line in sys.stdin:
    buffer.append(line)
    if line.strip() != 'flush stdout':
        continue
    request = ''.join(buffer)
    buffer = []
    request_id = re.search(r'__DIDE_BEGIN__:(\\d+)', request).group(1)
    if 'write_hw_ila_data' in request:
        with open(${JSON.stringify(fakeVivadoSleepStarted)}, 'w', encoding='utf-8') as stream:
            stream.write('started')
        time.sleep(30)
    print('__DIDE_BEGIN__:' + request_id)
    print('__DIDE_MSG__:' + request_id + ':')
    print('__DIDE_RC__:' + request_id + ':0')
    print('__DIDE_END__:' + request_id)
    sys.stdout.flush()
`,
    );
    fs.chmodSync(fakeVivado, 0o755);
    fs.chmodSync(fakeVivadoSleep, 0o755);
    fs.mkdirSync(secondaryWorkspacePath, { recursive: true });
    fs.mkdirSync(path.join(cancellationWorkspacePath, '.vscode'), { recursive: true });
    fs.mkdirSync(path.join(cancellationWorkspacePath, 'rtl'), { recursive: true });
    fs.mkdirSync(path.join(fakeEfinityPackage, 'bin'), { recursive: true });
    fs.mkdirSync(path.join(fakeEfinityPackage, 'lib'), { recursive: true });
    fs.writeFileSync(
        path.join(cancellationWorkspacePath, 'rtl', 'top.v'),
        'module cancellation_top; endmodule\n',
    );
    fs.writeFileSync(
        path.join(cancellationWorkspacePath, '.vscode', 'property.json'),
        JSON.stringify({
            toolChain: 'xilinx',
            prjName: { PL: 'cancellation' },
            arch: {
                prjPath: '${workspace}/build',
                hardware: {
                    src: '${workspace}/rtl',
                    sim: '${workspace}/sim',
                    data: '${workspace}/constraints',
                },
            },
            device: 'Ti60F100S3F2-C4',
            soc: { core: 'none' },
        }, null, 2),
    );
    const fakeMap = path.join(fakeEfinityPackage, 'bin', 'efx_map');
    fs.writeFileSync(
        fakeMap,
        '#!/bin/sh\necho digital-server-electron-cancel-started\nsleep 30\n',
    );
    fs.chmodSync(fakeMap, 0o755);
    const folders = [
        { path: workspacePath },
        { path: secondaryWorkspacePath },
    ];
    const vendorFixture = path.join(serverRoot, 'tests', 'project', 'xilinx', 'temp');
    const vendorCacheRoot = process.env.DIGITAL_VENDOR_SIM_CACHE_ROOT
        ?? path.join(vendorFixture, 'prj', 'simulation', 'vendor-cache');
    if (process.env.DIGITAL_TOOLCHAIN_E2E_MODE === 'xilinx-vendor-simulation') {
        const propertyDirectory = path.join(vendorSimulationWorkspacePath, '.vscode');
        const ipDirectory = path.join(
            vendorSimulationWorkspacePath,
            'user',
            'ip',
            'xfft_v9',
        );
        const simulationDirectory = path.join(vendorSimulationWorkspacePath, 'user', 'sim');
        fs.mkdirSync(propertyDirectory, { recursive: true });
        fs.mkdirSync(ipDirectory, { recursive: true });
        fs.mkdirSync(simulationDirectory, { recursive: true });
        fs.writeFileSync(
            path.join(propertyDirectory, 'property.json'),
            JSON.stringify({
                toolChain: 'xilinx',
                prjName: { PL: 'vendor_xfft' },
                device: 'xc7a35tftg256-1',
                arch: {
                    prjPath: '${workspace}/project/xilinx',
                    hardware: {
                        src: '${workspace}/user/src',
                        sim: '${workspace}/user/sim',
                        data: '${workspace}/user/data',
                    },
                },
                soc: { core: 'none' },
                simTop: 'fft_ifft_tb',
                library: {
                    state: 'remote',
                    hardware: {
                        common: [
                            'Basic/Memory/SRAM/Shift/shiftTaps.v',
                            'Basic/Math/Advance/Complex/cmplAdsu.v',
                            'Basic/Math/Advance/Complex/cmplMult.v',
                            'Basic/Memory/SRAM/SDPRAM.v',
                            'Basic/Math/Advance/Complex/cordic.v',
                            'Basic/Memory/SRAM/DPRAM.v',
                            'Basic/Math/FixedPoint/accuml.v',
                            'Basic/Source/LUT/Sin.v',
                            'Basic/Math/Advance/FFT/Flow',
                        ],
                        custom: [],
                    },
                },
            }, null, 2),
        );
        fs.copyFileSync(
            path.join(vendorFixture, 'user', 'ip', 'xfft_v9', 'xfft_v9.xci'),
            path.join(ipDirectory, 'xfft_v9.xci'),
        );
        fs.copyFileSync(
            path.join(vendorFixture, 'user', 'sim', 'fft', 'fft_ifft_tb.sv'),
            path.join(simulationDirectory, 'fft_ifft_tb.sv'),
        );
        fs.cpSync(
            path.join(vendorFixture, 'user', 'src'),
            path.join(vendorSimulationWorkspacePath, 'user', 'src'),
            { recursive: true },
        );
        folders.push({ path: vendorSimulationWorkspacePath });
    }
    const realToolchainWorkspace = process.env.DIGITAL_TOOLCHAIN_E2E_WORKSPACE;
    if (realToolchainWorkspace) {
        folders.push({ path: path.resolve(realToolchainWorkspace) });
    }
    fs.writeFileSync(
        workspaceFilePath,
        JSON.stringify({
            folders,
            settings: {
                'digital-ide.standard.systemverilog': '2023',
                'digital-ide.function.lsp.systemverilog.expandIncludes': true,
                'digital-ide.standard.vhdl': '2008',
                'digital-ide.function.lsp.linter.mode': 'full',
                'digital-ide.function.lsp.linter.linter-level': 'warning',
                'digital-ide.prj.vivado.install.path': process.env.DIDE_VIVADO_COMMAND
                    ?? fakeVivado,
                'digital-ide.prj.xsdk.install.path': process.env.DIDE_XSCT_COMMAND
                    ?? '/opt/xilinx/Vitis/2022.2/bin/xsct',
                'digital-ide.prj.efinix.package.path': process.env.DIDE_EFINITY_PACKAGE
                    ?? fakeEfinityPackage,
                'digital-ide.efinity.install.path': process.env.DIDE_EFINITY_INSTALL
                    ?? path.resolve(serverRoot, '..', 'efinity', '2026.1'),
                'digital-ide.prj.verilator.install.path': process.env.DIDE_VERILATOR_BIN
                    ?? '/home/icer/.local/bin',
                'digital-ide.prj.modelsim.install.path': process.env.DIDE_MODELSIM_BIN
                    ?? '',
                'digital-ide.function.simulate.vendorCachePath': vendorCacheRoot,
            },
        }),
    );

    const executable = process.platform === 'win32' ? 'digital-server.exe' : 'digital-server';
    const realServerPath = process.env.DIGITAL_SERVER_PATH
        ?? path.resolve(serverRoot, 'target', 'debug', executable);
    if (!fs.existsSync(realServerPath)) {
        throw new Error(`Digital Server test executable does not exist: ${realServerPath}`);
    }
    const coldTreeMode = process.env.DIGITAL_VSCODE_COLD_TREE === '1';
    let serverPath = realServerPath;
    if (coldTreeMode) {
        if (process.platform === 'win32') {
            throw new Error('The cold TreeView activation regression currently requires POSIX');
        }
        serverPath = path.join(temporaryRoot, 'delayed-digital-server');
        fs.writeFileSync(
            serverPath,
            `#!/usr/bin/env bash\nsleep 3\nexec ${JSON.stringify(realServerPath)} "$@"\n`,
        );
        fs.chmodSync(serverPath, 0o755);
    }

    const extensionTestsEnv = { ...process.env };
    delete extensionTestsEnv.ELECTRON_RUN_AS_NODE;
    if (requestedGrep) {
        extensionTestsEnv.DIGITAL_VSCODE_TEST_GREP = requestedGrep;
    }
    extensionTestsEnv.DIGITAL_SERVER_PATH = serverPath;
    extensionTestsEnv.DIGITAL_SERVER_VHDL_LIBRARY_PATH = process.env.DIGITAL_SERVER_VHDL_LIBRARY_PATH
        ?? path.resolve(extensionDevelopmentPath, 'resources', 'vhdl_libraries');
    extensionTestsEnv.DIGITAL_TEST_WORKSPACE = workspacePath;
    extensionTestsEnv.DIGITAL_TEST_SECONDARY_WORKSPACE = secondaryWorkspacePath;
    extensionTestsEnv.DIGITAL_TEST_CANCELLATION_WORKSPACE = cancellationWorkspacePath;
    extensionTestsEnv.DIGITAL_VENDOR_SIM_E2E_WORKSPACE = vendorSimulationWorkspacePath;
    extensionTestsEnv.DIGITAL_VENDOR_SIM_CACHE_ROOT = vendorCacheRoot;
    extensionTestsEnv.DIGITAL_VSCODE_TEST_POLLING_WATCHER = '1';
    extensionTestsEnv.DIGITAL_TEST_VIVADO_DEBUGGER = fakeVivado;
    extensionTestsEnv.DIGITAL_TEST_VIVADO_DEBUGGER_LAUNCHES = fakeVivadoLaunches;
    extensionTestsEnv.DIGITAL_TEST_VIVADO_DEBUGGER_REQUESTS = fakeVivadoRequests;
    extensionTestsEnv.DIGITAL_TEST_VIVADO_DEBUGGER_SLEEP = fakeVivadoSleep;
    extensionTestsEnv.DIGITAL_TEST_VIVADO_DEBUGGER_SLEEP_STARTED = fakeVivadoSleepStarted;
    extensionTestsEnv.DIGITAL_TEST_TOOLCHAIN_STARTED = fakeVivadoToolchainStarted;
    extensionTestsEnv.DIGITAL_TEST_WAVE_CAPTURE = waveCapture;
    if (coldTreeMode) {
        extensionTestsEnv.DIGITAL_TEST_COLD_TREE = '1';
        extensionTestsEnv.DIGITAL_VSCODE_TEST_GREP =
            'publishes static tool trees while backend initialization is pending';
    }

    if (!fs.existsSync(extensionTestsEnv.DIGITAL_SERVER_VHDL_LIBRARY_PATH)) {
        throw new Error(
            `Digital Server VHDL library does not exist: ${extensionTestsEnv.DIGITAL_SERVER_VHDL_LIBRARY_PATH}`,
        );
    }

    let waveServer: ChildProcess | undefined;
    try {
        const wsPath = require.resolve('ws');
        waveServer = spawn(process.execPath, ['-e', `
const fs = require(${JSON.stringify(require.resolve('fs'))});
const { WebSocketServer } = require(${JSON.stringify(wsPath)});
const ready = ${JSON.stringify(waveServerReady)};
const captureFile = ${JSON.stringify(waveCapture)};
const server = new WebSocketServer({ host: '127.0.0.1', port: 0 }, () => {
  fs.writeFileSync(ready, String(server.address().port));
});
server.on('connection', socket => socket.on('message', raw => {
  const request = JSON.parse(String(raw));
  fs.writeFileSync(captureFile, JSON.stringify(request));
  let end = 0;
  if (request.type === 'loadCapture') {
    const samples = request.capture.samples;
    end = samples.length === 0 ? 0 : samples[samples.length - 1].time;
  } else if (request.type === 'loadPackedCapture') {
    const raw = request.capture.raw.replace(/^0b/, '');
    const count = raw.length / request.capture.schema.sample_width;
    end = count === 0 ? 0 : (count - 1) * request.capture.schema.sample_period;
  }
  socket.send(JSON.stringify({
    type: 'capturePublished',
    name: request.name,
    time_range: [0, end],
    decode_us: 0,
  }));
}));
process.on('SIGTERM', () => server.close(() => process.exit(0)));
`], { stdio: 'inherit' });
        const deadline = Date.now() + 10_000;
        while (!fs.existsSync(waveServerReady)) {
            if (Date.now() >= deadline) {
                throw new Error('Timed out starting the desktop Wave Server fixture');
            }
            await new Promise(resolve => setTimeout(resolve, 20));
        }
        extensionTestsEnv.DIGITAL_TEST_WAVEFORM_URL = `ws://127.0.0.1:${fs.readFileSync(
            waveServerReady,
            'utf8',
        ).trim()}`;
        const rendererDebugPort = await reserveTcpPort();
        extensionTestsEnv.DIGITAL_TEST_RENDERER_DEBUG_PORT = String(rendererDebugPort);
        const rendererLaunchArgs = process.env.DIGITAL_VSCODE_TEST_FORCE_CANVAS === '1'
            ? ['--disable-gpu']
            : ['--enable-webgl', '--ignore-gpu-blocklist'];
        const exitCode = await runTests({
            version: process.env.VSCODE_TEST_VERSION ?? '1.129.1',
            extensionDevelopmentPath,
            extensionTestsPath,
            extensionTestsEnv,
            launchArgs: [
                workspaceFilePath,
                '--disable-extensions',
                ...rendererLaunchArgs,
                '--disable-updates',
                '--disable-workspace-trust',
                `--remote-debugging-port=${rendererDebugPort}`,
                '--skip-release-notes',
                '--skip-welcome',
                `--user-data-dir=${userDataPath}`,
                `--extensions-dir=${extensionsPath}`,
            ],
        });
        if (exitCode !== 0) {
            throw new Error(`VS Code Extension Host exited with code ${exitCode}`);
        }
    } finally {
        waveServer?.kill('SIGTERM');
        fs.rmSync(temporaryRoot, { recursive: true, force: true });
    }
}

main().catch(error => {
    console.error(error);
    process.exit(1);
});
