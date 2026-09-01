import * as assert from 'assert';
import * as fs from 'fs';
import * as path from 'path';
import * as net from 'net';
import * as vscode from 'vscode';
import {
    onDidShowToolchainMessage,
    onDidWriteToolchainOutput,
    ToolchainProgressEvent,
    ToolchainReport,
    ToolchainUserMessage,
    PsTargetInventory,
    PsTargetSelection,
} from '../../toolchain/commands';
import { SimulationResponse } from '../../simulation/commands';
import { activateExtension } from './helpers';

function realWorkspaceUri(): vscode.Uri {
    const workspace = process.env.DIGITAL_TOOLCHAIN_E2E_WORKSPACE;
    assert.ok(workspace, 'DIGITAL_TOOLCHAIN_E2E_WORKSPACE is required');
    return vscode.Uri.file(workspace);
}

function assertArtifacts(report: ToolchainReport, kinds: string[]): void {
    for (const kind of kinds) {
        const artifact = report.artifacts.find(candidate => candidate.kind === kind);
        assert.ok(artifact, `missing ${kind} artifact`);
        assert.ok(fs.statSync(artifact.path).size > 0, `empty ${kind}: ${artifact.path}`);
    }
}

function assertNoServerRootXil(): void {
    const serverRoot = path.resolve(__dirname, '..', '..', '..', '..', '..');
    assert.strictEqual(
        fs.existsSync(path.join(serverRoot, '.Xil')),
        false,
        `Xilinx runtime data leaked into ${serverRoot}`,
    );
}

function vendorSimulationWorkspaceUri(): vscode.Uri {
    const workspace = process.env.DIGITAL_VENDOR_SIM_E2E_WORKSPACE;
    assert.ok(workspace, 'DIGITAL_VENDOR_SIM_E2E_WORKSPACE is required');
    return vscode.Uri.file(workspace);
}

async function assertTcpEndpoint(host: string, port: number): Promise<void> {
    await new Promise<void>((resolve, reject) => {
        const socket = net.createConnection({ host, port });
        const timer = setTimeout(() => {
            socket.destroy();
            reject(new Error(`Timed out connecting to ${host}:${port}`));
        }, 3_000);
        socket.once('connect', () => {
            clearTimeout(timer);
            socket.destroy();
            resolve();
        });
        socket.once('error', error => {
            clearTimeout(timer);
            reject(error);
        });
    });
}

async function assertTcpEndpointClosed(host: string, port: number): Promise<void> {
    await new Promise<void>((resolve, reject) => {
        const socket = net.createConnection({ host, port });
        const timer = setTimeout(() => {
            socket.destroy();
            reject(new Error(`Timed out checking closed endpoint ${host}:${port}`));
        }, 3_000);
        socket.once('connect', () => {
            clearTimeout(timer);
            socket.destroy();
            reject(new Error(`Endpoint is still listening at ${host}:${port}`));
        });
        socket.once('error', () => {
            clearTimeout(timer);
            socket.destroy();
            resolve();
        });
    });
}

suite('Real vendor frontend to LSP end-to-end workflows', function () {
    this.timeout(20 * 60_000);

    test('runs the real Vivado hardware flow from VS Code commands', async function () {
        if (process.env.DIGITAL_TOOLCHAIN_E2E_MODE !== 'xilinx') {
            this.skip();
        }
        await activateExtension();
        const workspaceUri = realWorkspaceUri();
        const output: ToolchainProgressEvent[] = [];
        const messages: ToolchainUserMessage[] = [];
        const subscriptions = [
            onDidWriteToolchainOutput(event => output.push(event)),
            onDidShowToolchainMessage(message => messages.push(message)),
        ];
        try {
            for (const command of [
                'digital-ide.hard.launch',
                'digital-ide.hard.refresh',
                'digital-ide.hard.build.synth',
                'digital-ide.hard.build.impl',
            ]) {
                let report: ToolchainReport;
                try {
                    report = await vscode.commands.executeCommand<ToolchainReport>(
                        command,
                        { workspaceUri },
                    );
                } catch (error) {
                    throw new Error(`${command} failed: ${String(error)}`);
                }
                assert.strictEqual(report.success, true, `${command}: ${report.message}`);
            }
            const bitstream = await vscode.commands.executeCommand<ToolchainReport>(
                'digital-ide.hard.build.bitstream',
                { workspaceUri, silent: true },
            );
            assertArtifacts(bitstream, ['bitstream']);
            const exit = await vscode.commands.executeCommand<ToolchainReport>(
                'digital-ide.hard.exit',
                { workspaceUri, silent: true },
            );
            assert.strictEqual(exit.success, true);
            assert.ok(output.some(event => event.stream === 'stdout'));
            assert.ok(messages.some(message => message.kind === 'success'));
            assertNoServerRootXil();
        } finally {
            subscriptions.forEach(subscription => subscription.dispose());
        }
    });

    test('runs real Vivado refresh, simulation, and GUI commands from VS Code', async function () {
        if (process.env.DIGITAL_TOOLCHAIN_E2E_MODE !== 'xilinx-operations') {
            this.skip();
        }
        await activateExtension();
        const workspaceUri = realWorkspaceUri();
        const output: ToolchainProgressEvent[] = [];
        const subscription = onDidWriteToolchainOutput(event => output.push(event));
        try {
            for (const command of [
                'digital-ide.hard.launch',
                'digital-ide.hard.refresh',
                'digital-ide.hard.simulate',
                'digital-ide.hard.simulate.cli',
                'digital-ide.hard.gui',
                'digital-ide.hard.simulate.gui',
                'digital-ide.hard.exit',
            ]) {
                const report = await vscode.commands.executeCommand<ToolchainReport>(
                    command,
                    { workspaceUri, silent: true },
                );
                assert.strictEqual(report.success, true, `${command}: ${report.message}`);
            }
            assert.ok(output.some(event => event.stream === 'stdout'));
            assert.ok(output.some(event => event.message.includes('launch_simulation')));
            assert.ok(output.some(event => event.phase === 'gui-ready'));
            for (const category of ['bd', 'ip', 'remote_lib']) {
                const marker = new RegExp(
                    `digital_server_vivado_import:${category}:expected=[1-9][0-9]*:missing=0`,
                );
                assert.ok(
                    output.some(event => marker.test(event.message)),
                    `missing successful Vivado ${category} import marker`,
                );
            }
            assert.ok(output.some(event =>
                event.message.includes(
                    'digital_server_vivado_import:ip_repo:expected=0:missing=0',
                ),
            ));
            assertNoServerRootXil();
        } finally {
            subscription.dispose();
        }
    });

    test('runs the real Efinity build from a VS Code command', async function () {
        if (process.env.DIGITAL_TOOLCHAIN_E2E_MODE !== 'efinity') {
            this.skip();
        }
        await activateExtension();
        const output: ToolchainProgressEvent[] = [];
        const subscription = onDidWriteToolchainOutput(event => output.push(event));
        try {
            for (const command of [
                'digital-ide.hard.launch',
                'digital-ide.hard.refresh',
            ]) {
                const report = await vscode.commands.executeCommand<ToolchainReport>(
                    command,
                    { workspaceUri: realWorkspaceUri(), silent: true },
                );
                assert.strictEqual(report.success, true, `${command}: ${report.message}`);
            }
            const report = await vscode.commands.executeCommand<ToolchainReport>(
                'digital-ide.hard.build',
                { workspaceUri: realWorkspaceUri() },
            );
            assert.strictEqual(report.success, true, report.message);
            assertArtifacts(report, ['vdb', 'lbf', 'timingReport', 'hex', 'bitstream']);
            const exit = await vscode.commands.executeCommand<ToolchainReport>(
                'digital-ide.hard.exit',
                { workspaceUri: realWorkspaceUri(), silent: true },
            );
            assert.strictEqual(exit.success, true, exit.message);
            for (const stage of ['efx_map', 'efx_pnr', 'efx_pgm']) {
                assert.ok(output.some(event => event.phase === stage), `missing ${stage} progress`);
            }
        } finally {
            subscription.dispose();
        }
    });

    test('runs real Xilinx IP export and ModelSim through the unified command', async function () {
        if (process.env.DIGITAL_TOOLCHAIN_E2E_MODE !== 'xilinx-vendor-simulation') {
            this.skip();
        }
        await activateExtension();
        const workspaceUri = vendorSimulationWorkspaceUri();
        const fileUri = vscode.Uri.joinPath(workspaceUri, 'user', 'sim', 'fft_ifft_tb.sv');
        const request = {
            backend: 'modelsim' as const,
            workspaceUri,
            fileUri,
            moduleName: 'fft_ifft_tb',
            silent: true,
            options: { vendorRuntime: '200us' },
        };

        const first = await vscode.commands.executeCommand<SimulationResponse>(
            'digital-ide.tool.simulateFile',
            request,
        );
        assert.strictEqual(first.success, true, first.message);
        assert.strictEqual(first.exitCode, 0);
        assert.ok(
            first.stderr.includes('XFFT v9 regression passed')
                || first.stdout.includes('XFFT v9 regression passed'),
            'the XFFT testbench did not reach its successful finish marker',
        );
        for (const kind of [
            'vendorLibraryManifest',
            'modelsimIni',
            'vendorExportManifest',
            'vendorSimulationScript',
        ]) {
            const artifact = first.artifacts.find(candidate => candidate.kind === kind);
            assert.ok(artifact, `missing ${kind} artifact`);
            assert.ok(fs.existsSync(artifact.path), `missing ${kind}: ${artifact.path}`);
        }
        const firstReport = first.report as {
            cacheKey: Record<string, string>;
            cacheDir: string;
            ips: string[];
        };
        assert.deepStrictEqual(firstReport.cacheKey, {
            vendor: 'xilinx',
            toolVersion: '2022.2',
            simulator: 'modelsim',
            deviceFamily: 'artix7',
        });
        assert.strictEqual(firstReport.ips.length, 1);
        const expectedCache = process.env.DIGITAL_VENDOR_SIM_CACHE_ROOT;
        assert.ok(expectedCache, 'DIGITAL_VENDOR_SIM_CACHE_ROOT is required');
        assert.ok(
            path.resolve(firstReport.cacheDir).startsWith(path.resolve(expectedCache)),
            `vendor library was not stored under the configured cache: ${firstReport.cacheDir}`,
        );

        const cached = await vscode.commands.executeCommand<SimulationResponse>(
            'digital-ide.tool.simulateFile',
            request,
        );
        const cachedReport = cached.report as {
            cacheHit: boolean;
            exportCacheHit: boolean;
        };
        assert.strictEqual(cached.success, true, cached.message);
        assert.strictEqual(cachedReport.cacheHit, true);
        assert.strictEqual(cachedReport.exportCacheHit, true);
        assertNoServerRootXil();
    });

    test('creates and builds the real XSCT software workspace from VS Code commands', async function () {
        if (process.env.DIGITAL_TOOLCHAIN_E2E_MODE !== 'software') {
            this.skip();
        }
        await activateExtension();
        const workspaceUri = realWorkspaceUri();
        const output: ToolchainProgressEvent[] = [];
        const subscription = onDidWriteToolchainOutput(event => output.push(event));
        try {
            const launch = await vscode.commands.executeCommand<ToolchainReport>(
                'digital-ide.soft.launch',
                { workspaceUri },
            );
            assert.strictEqual(launch.success, true, launch.message);
            const build = await vscode.commands.executeCommand<ToolchainReport>(
                'digital-ide.soft.build',
                { workspaceUri },
            );
            assert.strictEqual(build.success, true, build.message);
            assertArtifacts(build, ['elf']);
            assert.ok(output.some(event => event.stream === 'stdout'));
            assertNoServerRootXil();
        } finally {
            subscription.dispose();
        }
    });

    test('signs off Xilinx PS download, control, and GDB on the connected board', async function () {
        if (process.env.DIGITAL_TOOLCHAIN_E2E_MODE !== 'xilinx-ps-board') {
            this.skip();
        }
        const api = await activateExtension();
        const workspaceUri = realWorkspaceUri();
        const inventory = await api.client.sendRequest<PsTargetInventory>(
            'digital/softwareTargets',
            { workspaceUri: workspaceUri.toString() },
        );
        const target = inventory.targets.find(candidate =>
            candidate.processorKind === 'zynq7000Arm' && candidate.appName === 'base');
        assert.ok(target, 'missing Zynq-7000 base target');
        assert.strictEqual(target.elfExists, true, `missing board ELF: ${target.elfPath}`);
        const selection: PsTargetSelection = {
            appName: target.appName,
            elfPath: target.elfPath,
            programBitstream: false,
        };
        const run = async (command: string): Promise<ToolchainReport> => {
            const report = await vscode.commands.executeCommand<ToolchainReport>(command, {
                workspaceUri,
                target: selection,
                programBitstream: false,
                silent: true,
            });
            assert.strictEqual(report.success, true, `${command}: ${report.message}`);
            return report;
        };
        const state = async (): Promise<PsTargetInventory> => api.client.sendRequest(
            'digital/softwareTargets',
            { workspaceUri: workspaceUri.toString() },
        );

        try {
            const download = await run('digital-ide.soft.download');
            assert.match(download.stdout, /digital_server_ps_state:Running/i);
            assert.strictEqual((await state()).runtime.execution, 'running');

            await run('digital-ide.soft.halt');
            assert.strictEqual((await state()).runtime.execution, 'stopped');
            await run('digital-ide.soft.run');
            assert.strictEqual((await state()).runtime.execution, 'running');
            await run('digital-ide.soft.reset');
            assert.strictEqual((await state()).runtime.execution, 'stopped');
            await run('digital-ide.soft.stop');
            assert.strictEqual((await state()).runtime.execution, 'stopped');
            await run('digital-ide.soft.status');

            await run('digital-ide.soft.gdb.start');
            const debugging = await state();
            assert.strictEqual(debugging.gdbServer.status, 'runningOwned');
            await assertTcpEndpoint(target.gdbHost, target.gdbPort);
            const configurations = vscode.workspace
                .getConfiguration('launch', workspaceUri)
                .get<vscode.DebugConfiguration[]>('configurations', []);
            const generated = configurations.find(candidate =>
                candidate.name === `Digital IDE: Zynq-7000 ARM Cortex-A9 ${target.appName}`);
            assert.ok(generated, 'missing generated Xilinx PS GDB configuration');
            assert.strictEqual(generated.program, target.elfPath);
            assert.strictEqual(generated.miDebuggerPath, target.gdbPath);
            assert.strictEqual(
                generated.miDebuggerServerAddress,
                `${target.gdbHost}:${target.gdbPort}`,
            );

            await run('digital-ide.soft.gdb.stop');
            assert.strictEqual((await state()).gdbServer.status, 'stopped');
            await assertTcpEndpointClosed(target.gdbHost, target.gdbPort);
            await assertTcpEndpointClosed(target.gdbHost, debugging.gdbServer.hwServerPort);
        } finally {
            await vscode.commands.executeCommand<ToolchainReport>(
                'digital-ide.soft.gdb.stop',
                { workspaceUri, silent: true },
            ).then(undefined, () => undefined);
        }
    });
});
