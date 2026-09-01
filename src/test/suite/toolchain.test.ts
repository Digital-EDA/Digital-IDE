import * as assert from 'assert';
import * as fs from 'fs';
import * as path from 'path';
import * as vscode from 'vscode';
import {
    onDidReceiveToolchainProgress,
    onDidShowToolchainMessage,
    onDidWriteToolchainOutput,
    ToolchainProgressEvent,
    ToolchainReport,
    ToolchainUserMessage,
} from '../../toolchain/commands';
import { activateExtension, waitFor } from './helpers';

const hardwareCommands = [
    'digital-ide.hard.launch',
    'digital-ide.hard.simulate',
    'digital-ide.hard.simulate.cli',
    'digital-ide.hard.simulate.gui',
    'digital-ide.hard.refresh',
    'digital-ide.hard.build',
    'digital-ide.hard.build.synth',
    'digital-ide.hard.build.impl',
    'digital-ide.hard.build.bitstream',
    'digital-ide.hard.program',
    'digital-ide.hard.program.sram',
    'digital-ide.hard.program.flash',
    'digital-ide.hard.gui',
    'digital-ide.hard.exit',
];

const hardwareDryRunCommands = hardwareCommands.filter(command =>
    command !== 'digital-ide.hard.program.flash');

const softwareCommands = [
    'digital-ide.soft.launch',
    'digital-ide.soft.build',
    'digital-ide.soft.download',
    'digital-ide.soft.selectElf',
    'digital-ide.soft.reset',
    'digital-ide.soft.halt',
    'digital-ide.soft.run',
    'digital-ide.soft.stop',
    'digital-ide.soft.status',
    'digital-ide.soft.gdb.start',
    'digital-ide.soft.gdb.generateConfig',
    'digital-ide.soft.gdb.stop',
];

const softwareDryRunCommands = softwareCommands.filter(command =>
    command !== 'digital-ide.soft.selectElf'
    && command !== 'digital-ide.soft.gdb.generateConfig');

interface HardwareTreeExpectation {
    label: string;
    command?: string;
    tooltip: string;
    icon: 'cmd' | 'toolBox' | 'branch';
    children?: HardwareTreeExpectation[];
}

const hardwareTree: HardwareTreeExpectation[] = [
    {
        label: 'Launch',
        command: 'digital-ide.hard.launch',
        tooltip: 'Launch FPGA development assist function',
        icon: 'cmd',
    },
    {
        label: 'Simulate',
        command: 'digital-ide.hard.simulate',
        tooltip: 'Launch the manufacturer Simulation',
        icon: 'toolBox',
        children: [
            {
                label: 'CLI',
                command: 'digital-ide.hard.simulate.cli',
                tooltip: 'Launch the manufacturer Simulation in CLI',
                icon: 'branch',
            },
            {
                label: 'GUI',
                command: 'digital-ide.hard.simulate.gui',
                tooltip: 'Launch the manufacturer Simulation in GUI',
                icon: 'branch',
            },
        ],
    },
    {
        label: 'Refresh',
        command: 'digital-ide.hard.refresh',
        tooltip: 'Refresh the current project file',
        icon: 'cmd',
    },
    {
        label: 'Build',
        command: 'digital-ide.hard.build',
        tooltip: 'Build the current fpga project',
        icon: 'toolBox',
        children: [
            {
                label: 'Synth',
                command: 'digital-ide.hard.build.synth',
                tooltip: 'Synth the current project',
                icon: 'branch',
            },
            {
                label: 'Impl',
                command: 'digital-ide.hard.build.impl',
                tooltip: 'Impl the current project',
                icon: 'branch',
            },
            {
                label: 'BitStream',
                command: 'digital-ide.hard.build.bitstream',
                tooltip: 'Generate the BIT File',
                icon: 'branch',
            },
        ],
    },
    {
        label: 'Program',
        tooltip: 'Program the FPGA SRAM or configuration Flash',
        icon: 'toolBox',
        children: [
            {
                label: 'SRAM',
                command: 'digital-ide.hard.program.sram',
                tooltip: 'Download the bitstream into FPGA SRAM',
                icon: 'branch',
            },
            {
                label: 'FLASH',
                command: 'digital-ide.hard.program.flash',
                tooltip: 'Program the persistent FPGA configuration Flash',
                icon: 'branch',
            },
        ],
    },
    {
        label: 'GUI',
        command: 'digital-ide.hard.gui',
        tooltip: 'Open the GUI',
        icon: 'cmd',
    },
    {
        label: 'Exit',
        command: 'digital-ide.hard.exit',
        tooltip: 'Exit the current project',
        icon: 'cmd',
    },
];

const softwareTree: HardwareTreeExpectation[] = [
    {
        label: 'Launch',
        command: 'digital-ide.soft.launch',
        tooltip: 'Launch SDK development assist function',
        icon: 'cmd',
    },
    {
        label: 'Build',
        command: 'digital-ide.soft.build',
        tooltip: 'Build the current SDK project',
        icon: 'cmd',
    },
    {
        label: 'Select ELF',
        command: 'digital-ide.soft.selectElf',
        tooltip: 'Select and remember an ELF for the active processor target',
        icon: 'cmd',
    },
    processorTreeExpectation('Zynq-7000'),
    processorTreeExpectation('Zynq UltraScale+ MPSoC'),
    processorTreeExpectation('MicroBlaze'),
    {
        label: 'GDB Server',
        command: 'digital-ide.soft.gdb.start',
        tooltip: 'Manage the Xilinx PS GDB server and VS Code debug configuration',
        icon: 'toolBox',
        children: [
            {
                label: 'Start and Prepare',
                command: 'digital-ide.soft.gdb.start',
                tooltip: 'Start the Xilinx GDB server and generate a debug configuration',
                icon: 'branch',
            },
            {
                label: 'Generate Configuration',
                command: 'digital-ide.soft.gdb.generateConfig',
                tooltip: 'Generate or update the selected processor debug configuration',
                icon: 'branch',
            },
            {
                label: 'Stop Managed Server',
                command: 'digital-ide.soft.gdb.stop',
                tooltip: 'Stop only the hw_server process managed by Digital IDE',
                icon: 'branch',
            },
        ],
    },
];

function processorTreeExpectation(label: string): HardwareTreeExpectation {
    const actions: Array<[string, string, string]> = [
        ['Download and Run', 'digital-ide.soft.download', 'Download the selected ELF and continue execution'],
        ['Reset', 'digital-ide.soft.reset', 'Reset the selected processor and leave it stopped'],
        ['Halt', 'digital-ide.soft.halt', 'Halt the selected processor'],
        ['Run', 'digital-ide.soft.run', 'Continue the selected processor'],
        ['Stop', 'digital-ide.soft.stop', 'Stop the selected processor'],
        ['Status', 'digital-ide.soft.status', 'Read the selected processor execution state'],
    ];
    return {
        label,
        command: 'digital-ide.soft.selectElf',
        tooltip: `Manage downloads and execution state for ${label} processors`,
        icon: 'toolBox',
        children: actions.map(([actionLabel, command, tooltip]) => ({
            label: actionLabel,
            command,
            tooltip,
            icon: 'branch',
        })),
    };
}

suite('Hardware and software toolchain commands', () => {
    test('registers every Hardware and Software command', async () => {
        await activateExtension();
        const commands = new Set(await vscode.commands.getCommands(true));
        for (const command of [...hardwareCommands, ...softwareCommands]) {
            assert.ok(commands.has(command), `missing registered command ${command}`);
        }
    });

    test('reproduces the complete 0.4 HARD Options tree surface', async () => {
        const api = await activateExtension();
        const project = api.project;
        assert.ok(project, 'project extension API is unavailable');
        const commands: string[] = [];

        const assertNode = (
            node: ReturnType<typeof project.hardwareRoots>[number],
            expected: HardwareTreeExpectation,
        ): void => {
            const item = project.hardwareTreeItem(node);
            assert.strictEqual(item.label, expected.label);
            assert.strictEqual(item.contextValue, 'HARD');
            assert.strictEqual(item.tooltip, expected.tooltip);
            assert.strictEqual(item.command?.command, expected.command);
            assert.strictEqual(item.command?.title, expected.command);
            assert.strictEqual(
                item.collapsibleState,
                expected.children
                    ? vscode.TreeItemCollapsibleState.Collapsed
                    : vscode.TreeItemCollapsibleState.None,
            );
            const icon = item.iconPath as { light: vscode.Uri; dark: vscode.Uri };
            assert.strictEqual(path.basename(icon.light.fsPath), `${expected.icon}.svg`);
            assert.strictEqual(path.basename(icon.dark.fsPath), `${expected.icon}.svg`);
            assert.strictEqual(node.children.length, expected.children?.length ?? 0);
            if (expected.command) {
                commands.push(expected.command);
            }
            node.children.forEach((child, index) => {
                assertNode(child, expected.children![index]);
            });
        };

        const roots = project.hardwareRoots();
        assert.strictEqual(roots.length, hardwareTree.length);
        roots.forEach((root, index) => assertNode(root, hardwareTree[index]));
        assert.deepStrictEqual(
            [...commands].sort(),
            hardwareCommands.filter(command => command !== 'digital-ide.hard.program').sort(),
        );
    });

    test('reproduces the complete 0.4 SOFT Options tree surface', async () => {
        const api = await activateExtension();
        const project = api.project;
        assert.ok(project, 'project extension API is unavailable');
        const extension = vscode.extensions.getExtension('sterben.fpga-support');
        assert.ok(extension, 'extension package is unavailable');
        const contributedViews = extension.packageJSON.contributes.views.TreeView as Array<{
            id: string;
            name: string;
            icon?: string;
            visibility?: string;
        }>;
        const view = contributedViews.find(item => item.id === 'digital-ide-treeView-software');
        assert.deepStrictEqual(view, {
            id: 'digital-ide-treeView-software',
            name: 'SOFT Options',
            icon: 'images/svg/view.svg',
            visibility: 'collapsed',
        });

        const commands: string[] = [];
        const assertNode = (
            node: ReturnType<typeof project.softwareRoots>[number],
            expected: HardwareTreeExpectation,
        ): void => {
            const item = project.softwareTreeItem(node);
            assert.strictEqual(item.label, expected.label);
            assert.strictEqual(item.contextValue, 'SOFT');
            assert.strictEqual(item.tooltip, expected.tooltip);
            assert.strictEqual(item.command?.command, expected.command);
            assert.strictEqual(item.command?.title, expected.command);
            assert.strictEqual(
                item.collapsibleState,
                expected.children
                    ? vscode.TreeItemCollapsibleState.Collapsed
                    : vscode.TreeItemCollapsibleState.None,
            );
            const icon = item.iconPath as { light: vscode.Uri; dark: vscode.Uri };
            assert.strictEqual(path.basename(icon.light.fsPath), `${expected.icon}.svg`);
            assert.strictEqual(path.basename(icon.dark.fsPath), `${expected.icon}.svg`);
            assert.strictEqual(node.children.length, expected.children?.length ?? 0);
            if (expected.command) {
                commands.push(expected.command);
            }
            node.children.forEach((child, index) => {
                assertNode(child, expected.children![index]);
            });
        };
        const roots = project.softwareRoots();
        assert.strictEqual(roots.length, softwareTree.length);
        roots.forEach((node, index) => assertNode(node, softwareTree[index]));
        assert.deepStrictEqual(
            [...new Set(commands)].sort(),
            [...softwareCommands].sort(),
        );
    });

    test('executes every Hardware command through the server in dry-run mode', async () => {
        await activateExtension();
        for (const command of hardwareDryRunCommands) {
            const report = await vscode.commands.executeCommand<ToolchainReport>(
                command,
                { dryRun: true, silent: true },
            );
            assert.strictEqual(report.success, true, `${command}: ${report.message}`);
            assert.strictEqual(report.vendor, 'xilinx');
            assert.strictEqual(report.domain, 'hardware');
            assert.strictEqual(report.status, 'planned');
            assert.ok(report.stdout.length > 0, `${command} returned no execution plan`);
        }
    });

    test('routes Program SRAM and FLASH to distinct hardware actions', async () => {
        await activateExtension();
        const sram = await vscode.commands.executeCommand<ToolchainReport>(
            'digital-ide.hard.program.sram',
            { dryRun: true, silent: true },
        );
        assert.strictEqual(sram.action, 'program');
        await assert.rejects(
            async () => vscode.commands.executeCommand(
                'digital-ide.hard.program.flash',
                { dryRun: true, silent: true },
            ),
            /property flash is required before programming configuration memory/,
        );
    });

    test('executes the complete Software workflow through the server in dry-run mode', async () => {
        await activateExtension();
        const progressEvents: ToolchainProgressEvent[] = [];
        const outputEvents: ToolchainProgressEvent[] = [];
        const subscriptions = [
            onDidReceiveToolchainProgress(event => progressEvents.push(event)),
            onDidWriteToolchainOutput(event => outputEvents.push(event)),
        ];
        try {
            for (const command of softwareDryRunCommands) {
                const report = await vscode.commands.executeCommand<ToolchainReport>(
                    command,
                    { dryRun: true, silent: true },
                );
                assert.strictEqual(report.success, true, `${command}: ${report.message}`);
                assert.strictEqual(report.vendor, 'xilinx');
                assert.strictEqual(report.domain, 'software');
                assert.strictEqual(report.status, 'planned');
                assert.ok(report.artifacts.length > 0);
                const requestSuffix = `-software-${report.action}`;
                assert.ok(progressEvents.some(event =>
                    event.requestId.endsWith(requestSuffix) && event.phase === 'started'));
                assert.ok(outputEvents.some(event =>
                    event.requestId.endsWith(requestSuffix) && event.stream === 'stdout'));
            }
        } finally {
            subscriptions.forEach(subscription => subscription.dispose());
        }
    });

    test('reports the precise backend error when SOFT is used by a non-SoC project', async () => {
        const api = await activateExtension();
        const workspace = process.env.DIGITAL_TEST_CANCELLATION_WORKSPACE;
        assert.ok(workspace, 'missing non-SoC workspace');
        const workspaceUri = vscode.Uri.file(workspace);
        const before = vscode.workspace.workspaceFolders?.length ?? 0;
        assert.ok(vscode.workspace.updateWorkspaceFolders(before, 0, {
            uri: workspaceUri,
            name: 'non-soc-software-validation',
        }));
        await waitFor(
            'non-SoC workspace to reach the server',
            () => api.client.sendRequest<{ workspaceRoots: string[] }>('digital/debugState', {}),
            state => state.workspaceRoots.includes(workspaceUri.fsPath),
            60_000,
        );
        const messages: ToolchainUserMessage[] = [];
        const subscription = onDidShowToolchainMessage(message => messages.push(message));
        try {
            await assert.rejects(
                async () => vscode.commands.executeCommand(
                    'digital-ide.soft.launch',
                    { dryRun: true, workspaceUri },
                ),
                /requires property soc\.core to select a processor/,
            );
            assert.ok(messages.some(message => message.kind === 'error'));
        } finally {
            subscription.dispose();
            const index = vscode.workspace.workspaceFolders?.findIndex(
                folder => folder.uri.toString() === workspaceUri.toString(),
            ) ?? -1;
            if (index >= 0) {
                assert.ok(vscode.workspace.updateWorkspaceFolders(index, 1));
                await waitFor(
                    'non-SoC workspace removal to reach the server',
                    () => api.client.sendRequest<{ workspaceRoots: string[] }>(
                        'digital/debugState',
                        {},
                    ),
                    state => !state.workspaceRoots.includes(workspaceUri.fsPath),
                    60_000,
                );
            }
        }
    });

    test('streams progress into OUTPUT and reports success', async () => {
        await activateExtension();
        const progressEvents: ToolchainProgressEvent[] = [];
        const outputEvents: ToolchainProgressEvent[] = [];
        const messages: ToolchainUserMessage[] = [];
        const subscriptions = [
            onDidReceiveToolchainProgress(event => progressEvents.push(event)),
            onDidWriteToolchainOutput(event => outputEvents.push(event)),
            onDidShowToolchainMessage(message => messages.push(message)),
        ];
        try {
            const report = await vscode.commands.executeCommand<ToolchainReport>(
                'digital-ide.hard.build.synth',
                { dryRun: true },
            );
            assert.strictEqual(report.success, true);
            assert.ok(progressEvents.some(event => event.phase === 'started'));
            assert.ok(progressEvents.some(event => event.stream === 'stdout'));
            assert.ok(outputEvents.some(event => event.stream === 'stdout'));
            assert.ok(messages.some(message => message.kind === 'success'));
        } finally {
            subscriptions.forEach(subscription => subscription.dispose());
        }
    });

    test('reports failed toolchain requests with an error message', async () => {
        await activateExtension();
        const messages: ToolchainUserMessage[] = [];
        const subscription = onDidShowToolchainMessage(message => messages.push(message));
        try {
            await assert.rejects(
                async () => vscode.commands.executeCommand(
                    'digital-ide.hard.build.synth',
                    { dryRun: true, workspaceUri: vscode.Uri.file('/not-a-workspace') },
                ),
                /workspace is not initialized/,
            );
            assert.ok(messages.some(message => message.kind === 'error'));
        } finally {
            subscription.dispose();
        }
    });

    test('cancels a running backend process from the frontend token', async function () {
        if (process.env.DIGITAL_TOOLCHAIN_E2E_MODE) {
            this.skip();
        }
        const api = await activateExtension();
        const workspace = process.env.DIGITAL_TEST_CANCELLATION_WORKSPACE;
        assert.ok(workspace, 'missing cancellation workspace');
        const workspaceUri = vscode.Uri.file(workspace);
        const before = vscode.workspace.workspaceFolders?.length ?? 0;
        assert.ok(vscode.workspace.updateWorkspaceFolders(before, 0, {
            uri: workspaceUri,
            name: 'toolchain-cancellation',
        }));
        await waitFor(
            'cancellation workspace to reach the server',
            () => api.client.sendRequest<{ workspaceRoots: string[] }>('digital/debugState', {}),
            state => state.workspaceRoots.includes(workspaceUri.fsPath),
            60_000,
        );
        const cancellation = new vscode.CancellationTokenSource();
        const progressEvents: ToolchainProgressEvent[] = [];
        const messages: ToolchainUserMessage[] = [];
        const subscriptions = [
            onDidReceiveToolchainProgress(event => progressEvents.push(event)),
            onDidShowToolchainMessage(message => messages.push(message)),
        ];
        try {
            const execution = vscode.commands.executeCommand<ToolchainReport>(
                'digital-ide.hard.build.synth',
                {
                    workspaceUri,
                    cancellationToken: cancellation.token,
                },
            );
            const started = process.env.DIGITAL_TEST_TOOLCHAIN_STARTED;
            assert.ok(started, 'missing toolchain process start marker');
            await waitFor(
                'the cancellable Vivado toolchain process to start',
                () => fs.existsSync(started),
                Boolean,
                5_000,
            );
            cancellation.cancel();
            const report = await execution;
            assert.strictEqual(report.status, 'cancelled');
            assert.ok(progressEvents.some(event => event.phase === 'started'));
            assert.ok(progressEvents.some(event => event.phase === 'running'));
            assert.ok(progressEvents.some(event => event.phase === 'cancelled'));
            assert.ok(messages.some(message => message.kind === 'cancelled'));
        } finally {
            subscriptions.forEach(subscription => subscription.dispose());
            cancellation.dispose();
            const index = vscode.workspace.workspaceFolders?.findIndex(
                folder => folder.uri.toString() === workspaceUri.toString(),
            ) ?? -1;
            if (index >= 0) {
                assert.ok(vscode.workspace.updateWorkspaceFolders(index, 1));
                await waitFor(
                    'cancellation workspace removal to reach the server',
                    () => api.client.sendRequest<{ workspaceRoots: string[] }>(
                        'digital/debugState',
                        {},
                    ),
                    state => !state.workspaceRoots.includes(workspaceUri.fsPath),
                    60_000,
                );
            }
        }
    });
});
