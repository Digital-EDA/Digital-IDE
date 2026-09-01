import * as assert from 'assert';
import * as fs from 'fs';
import * as path from 'path';
import * as vscode from 'vscode';
import {
    activateExtension,
    closeDocument,
    flattenDocumentSymbols,
    openFixture,
    waitFor,
    workspacePath,
    workspaceUri,
    writeFixture,
} from './helpers';

suite('Project architecture and library management', () => {
    test('builds the architecture from the shared DesignGraph and opens declarations', async () => {
        const api = await activateExtension();
        assert.ok(api.project);
        const roots = api.project.architectureRoots();
        assert.deepStrictEqual(roots.map(root => root.name), ['src', 'sim']);
        const [srcRoot, simRoot] = roots;
        for (const root of roots) {
            const item = api.project.architectureTreeItem(root);
            assert.strictEqual(item.collapsibleState, vscode.TreeItemCollapsibleState.Expanded);
            assert.strictEqual(item.contextValue, 'other');
            assert.strictEqual(item.tooltip, 'src');
            assertIcon(item, `${root.name}.svg`);
        }

        const snapshot = await waitFor(
            'the background DesignGraph initialization',
            () => api.project!.refreshArchitecture(),
            value => value.modules.some(module => module.name === 'child'),
        );
        const child = snapshot.modules.find(module => module.name === 'child');
        assert.ok(child, 'child module was not present in the architecture snapshot');
        assert.ok(snapshot.modules.some(module => module.name === 'top'));
        assert.ok(snapshot.digest.length > 0);
        const top = snapshot.roots.find(module => module.label === 'top');
        assert.ok(top, 'top module was not present in the DesignGraph hierarchy');
        assert.ok(top.children.some(instance => instance.label.includes('child')));

        assert.ok(srcRoot.children.length > 0);
        assert.ok(simRoot.children.length === 0);
        const vhdlTop = srcRoot.children.find(node => path.basename(node.path ?? '') === 'top.vhd');
        assert.ok(vhdlTop, 'the VHDL top was not present below the src root');
        assert.strictEqual(vhdlTop.name, 'top_vhdl(rtl)');
        assert.strictEqual(api.project.architectureTreeItem(vhdlTop).label, 'top_vhdl(rtl)');
        const ipTop = srcRoot.children.find(node => node.name === 'demo(rtl)');
        assert.ok(ipTop, 'the Xilinx IP wrapper was not present below the src root');
        assert.strictEqual(ipTop.icon, 'ip');
        assert.strictEqual(ipTop.path, path.join(workspacePath(), 'ip', 'demo'));
        const ipItem = api.project.architectureTreeItem(ipTop);
        assert.strictEqual(ipItem.label, 'demo(rtl)');
        assert.strictEqual(ipItem.contextValue, 'file');
        assert.strictEqual(ipItem.tooltip, ipTop.path);
        assertIcon(ipItem, 'ip.svg');
        const ipEditor = await vscode.commands.executeCommand<vscode.TextEditor>(
            ipItem.command!.command,
            ...ipItem.command!.arguments!,
        );
        assert.strictEqual(
            ipEditor.document.uri.fsPath,
            path.join(workspacePath(), 'ip', 'demo', 'synth', 'demo.vhd'),
        );
        const dependencyMaximum = Math.max(...srcRoot.children.map(node => node.dependencyCount));
        assert.strictEqual(srcRoot.children[0].dependencyCount, dependencyMaximum);
        assert.strictEqual(srcRoot.children[0].icon, 'current-src-top');
        assertIcon(api.project.architectureTreeItem(srcRoot.children[0]), 'current-src-top.svg');

        const topNode = srcRoot.children.find(node => node.name === 'top');
        assert.ok(topNode, 'top module was not present below the src root');
        const childNode = topNode.children.find(node => node.name === 'child');
        assert.ok(childNode, 'child instance was not present below top');
        const childItem = api.project.architectureTreeItem(childNode);
        assert.strictEqual(childItem.label, 'u_child(child)');
        assert.strictEqual(childItem.contextValue, 'file');
        assert.strictEqual(childItem.tooltip, child.path);
        assert.strictEqual(childItem.collapsibleState, vscode.TreeItemCollapsibleState.Collapsed);
        assertIcon(childItem, 'systemverilog.svg');
        assert.strictEqual(childItem.command?.command, 'digital-ide.treeView.arch.openFile');
        assert.deepStrictEqual(childItem.command?.arguments, [
            childNode.path,
            childNode.range,
            childNode,
        ]);
        const editor = await vscode.commands.executeCommand<vscode.TextEditor>(
            childItem.command!.command,
            ...childItem.command!.arguments!,
        );
        assert.strictEqual(editor.document.uri.fsPath, child.path);
        assert.ok(fs.existsSync(editor.document.uri.fsPath));
        assert.deepStrictEqual(editor.selection.start, childNode.range?.start);
        assert.deepStrictEqual(editor.selection.end, childNode.range?.end);

        const primitiveTop = srcRoot.children.find(node => node.name === 'xilinx_primitive_top');
        assert.ok(primitiveTop, 'the Xilinx primitive fixture was not present below the src root');
        const primitive = primitiveTop.children.find(node => node.name === 'IBUF');
        assert.ok(primitive, 'the unresolved Xilinx primitive was not present in the tree');
        const primitiveItem = api.project.architectureTreeItem(primitive);
        assert.strictEqual(primitiveItem.label, 'u_ibuf(IBUF)');
        assert.strictEqual(primitiveItem.contextValue, 'other');
        assertIcon(primitiveItem, 'cells.svg');
        const unresolved = primitiveTop.children.find(node => node.name === 'missing_block');
        assert.ok(unresolved, 'the unresolved ordinary module was not present in the tree');
        const unresolvedItem = api.project.architectureTreeItem(unresolved);
        assert.strictEqual(unresolvedItem.label, 'missing_block');
        assert.strictEqual(unresolvedItem.contextValue, 'other');
        assertIcon(unresolvedItem, 'File Error.svg');
    });

    test('moves a selected source top and its legacy current-top icon to the first row', async () => {
        const api = await activateExtension();
        assert.ok(api.project);
        await api.project.refreshArchitecture();
        const srcRoot = api.project.architectureRoots()[0];
        const selected = srcRoot.children.find(node => node !== srcRoot.children[0]);
        assert.ok(selected, 'the fixture needs at least two source top modules');
        const propertyFile = workspaceUri('.vscode/property.json').fsPath;
        const original = JSON.parse(fs.readFileSync(propertyFile, 'utf8'));
        try {
            await vscode.commands.executeCommand('digital-ide.pl.setSrcTop', selected);
            assert.strictEqual(srcRoot.children[0].name, selected.name);
            assert.strictEqual(srcRoot.children[0].path, selected.path);
            assert.strictEqual(srcRoot.children[0].icon, 'current-src-top');
            assert.ok(srcRoot.children.slice(1).every(node => node.icon !== 'current-src-top'));
        } finally {
            await vscode.commands.executeCommand('digital-ide.property-json.overwrite', {
                workspaceUri: vscode.Uri.file(workspacePath()),
                property: original,
                silent: true,
            });
        }
    });

    test('keeps the legacy Architecture surface with one-position expand and collapse actions', () => {
        const extension = vscode.extensions.getExtension('sterben.fpga-support');
        assert.ok(extension);
        const contributes = extension.packageJSON.contributes as {
            commands: Array<Record<string, unknown>>;
            menus: Record<string, Array<Record<string, unknown>>>;
            views: { TreeView: Array<Record<string, unknown>> };
        };
        assert.deepStrictEqual(
            contributes.views.TreeView.find(view => view.id === 'digital-ide-treeView-arch'),
            {
                id: 'digital-ide-treeView-arch',
                name: 'architecture',
                icon: 'images/svg/view.svg',
            },
        );
        assert.deepStrictEqual(
            contributes.menus['view/title'].filter(item =>
                typeof item.when === 'string'
                && item.when.includes('view == digital-ide-treeView-arch')),
            [
                {
                    command: 'digital-ide.treeView.arch.collapse',
                    group: 'navigation',
                    when: 'view == digital-ide-treeView-arch && !TOOL-tree-expand',
                },
                {
                    command: 'digital-ide.treeView.arch.expand',
                    group: 'navigation',
                    when: 'view == digital-ide-treeView-arch && TOOL-tree-expand',
                },
                {
                    command: 'digital-ide.pickLibrary',
                    group: 'navigation',
                    when: 'view == digital-ide-treeView-arch',
                },
                {
                    command: 'digital-ide.treeView.arch.refresh',
                    group: 'navigation',
                    when: 'view == digital-ide-treeView-arch',
                },
            ],
        );
        assert.deepStrictEqual(
            contributes.menus['view/item/context'].filter(item =>
                typeof item.when === 'string'
                && item.when.includes('view == digital-ide-treeView-arch')),
            legacyArchitectureItemMenus(),
        );
        const commands = new Map(contributes.commands.map(command => [command.command, command]));
        assert.deepStrictEqual(commands.get('digital-ide.tool.icarus.simulateFile')?.icon, {
            light: 'images/svg/light/debug.svg',
            dark: 'images/svg/dark/debug.svg',
        });
        assert.deepStrictEqual(commands.get('digital-ide.netlist.treeview')?.icon, {
            light: 'images/svg/light/netlist.svg',
            dark: 'images/svg/dark/netlist.svg',
        });
        assert.deepStrictEqual(commands.get('digital-ide.tool.export-filelist')?.icon, {
            light: 'images/svg/light/export.svg',
            dark: 'images/svg/dark/export.svg',
        });
    });

    test('expands in place, collapses, and refreshes the real TreeView provider', async () => {
        const api = await activateExtension();
        const project = api.project;
        assert.ok(project);
        await project.refreshArchitecture();
        const roots = project.architectureRoots();
        const branch = roots
            .flatMap(root => root.children)
            .find(node => node.children.length > 0);
        assert.ok(branch, 'the fixture needs an expandable architecture branch');
        const collapsedBranchItem = project.architectureTreeItem(branch);
        assert.strictEqual(
            collapsedBranchItem.collapsibleState,
            vscode.TreeItemCollapsibleState.Collapsed,
        );

        const expanded = await vscode.commands.executeCommand<number>(
            'digital-ide.treeView.arch.expand',
        );
        assert.ok(expanded > 0, 'the command did not schedule any expandable TreeView elements');
        assert.ok(roots.every(root =>
            project.architectureTreeItem(root).collapsibleState
                === vscode.TreeItemCollapsibleState.Expanded));
        const expandedBranchItem = project.architectureTreeItem(branch);
        assert.strictEqual(
            expandedBranchItem.collapsibleState,
            vscode.TreeItemCollapsibleState.Expanded,
        );
        assert.notStrictEqual(expandedBranchItem.id, collapsedBranchItem.id);

        await vscode.commands.executeCommand('digital-ide.treeView.arch.collapse');
        assert.ok(roots.every(root =>
            project.architectureTreeItem(root).collapsibleState
                === vscode.TreeItemCollapsibleState.Collapsed));
        assert.strictEqual(
            project.architectureTreeItem(branch).collapsibleState,
            vscode.TreeItemCollapsibleState.Collapsed,
        );

        const refreshed = await waitFor(
            'Architecture TreeView to finish the preceding property refresh',
            async () => vscode.commands.executeCommand<{ modules: unknown[] }>(
                'digital-ide.treeView.arch.refresh',
            ),
            value => value.modules.length > 0,
        );
        assert.ok(refreshed.modules.length > 0);
    });

    test('publishes a new DesignGraph identity after an HDL watcher update', async function () {
        this.timeout(60_000);
        const api = await activateExtension();
        const before = await vscode.commands.executeCommand<{ digest: string }>(
            'digital-ide.treeView.arch.refresh',
        );
        let subscription: vscode.Disposable | undefined;
        let updateTimer: NodeJS.Timeout | undefined;
        const updated = new Promise<{ digest: string }>((resolve, reject) => {
            updateTimer = setTimeout(
                () => reject(new Error('DesignGraph update notification timed out')),
                30_000,
            );
            subscription = api.client.onNotification(
                'custom/designGraphUpdated',
                (payload: { digest: string }) => {
                    if (payload.digest === before.digest) {
                        return;
                    }
                    clearTimeout(updateTimer);
                    resolve(payload);
                },
            );
        });
        try {
            await writeFixture(
                'src/sv/architecture_live_update.sv',
                'module architecture_live_update; endmodule\n',
            );
            const identity = await updated;
            assert.notStrictEqual(identity.digest, before.digest);
            const snapshot = await waitFor(
                'Architecture TreeView to observe the DesignGraph update',
                async () => vscode.commands.executeCommand<{
                    modules: Array<{ name: string }>;
                }>('digital-ide.treeView.arch.refresh'),
                value => value.modules.some(module => module.name === 'architecture_live_update'),
            );
            assert.ok(snapshot.modules.some(module => module.name === 'architecture_live_update'));
        } finally {
            clearTimeout(updateTimer);
            subscription?.dispose();
        }
    });

    test('keeps an explicitly opened dideignored HDL file out of Architecture', async () => {
        const api = await activateExtension();
        assert.ok(api.project);
        const ignoredSources = [
            {
                file: 'src/ignored/ignored_architecture_top.sv',
                moduleName: 'ignored_architecture_top',
            },
            {
                file: 'src/ignored/ignored_architecture_vhdl.vhd',
                moduleName: 'ignored_architecture_vhdl',
            },
        ];
        const before = await api.project.refreshArchitecture();
        for (const source of ignoredSources) {
            assert.ok(!before.modules.some(module => module.name === source.moduleName));

            const document = await openFixture(source.file);
            try {
                const symbols = await vscode.commands.executeCommand<
                    Array<vscode.DocumentSymbol | vscode.SymbolInformation>
                >('vscode.executeDocumentSymbolProvider', document.uri);
                assert.ok(flattenDocumentSymbols(symbols)
                    .some(name => name.toLowerCase().includes(source.moduleName)));

                const after = await api.project.refreshArchitecture();
                assert.ok(!after.modules.some(module => module.name === source.moduleName));
                assert.ok(!after.roots.some(root => root.name === source.moduleName));
            } finally {
                await closeDocument(document);
            }
        }
    });

    test('updates Library mounts through LSP and reflects them in the architecture snapshot', async () => {
        const propertyFile = workspaceUri('.vscode/property.json').fsPath;
        const original = JSON.parse(fs.readFileSync(propertyFile, 'utf8'));
        try {
            const response = await vscode.commands.executeCommand<{ success: boolean }>(
                'digital-ide.pickLibrary',
                {
                    workspaceUri: vscode.Uri.file(workspacePath()),
                    mode: 'local',
                    common: ['Basic/Memory/SRAM/DPRAM.v'],
                    custom: ['src/sv'],
                    silent: true,
                },
            );
            assert.strictEqual(response.success, true);
            const snapshot = await vscode.commands.executeCommand<{
                libraries: { mode: string; common: string[]; custom: string[] };
            }>('digital-ide.treeView.arch.refresh');
            assert.strictEqual(snapshot.libraries.mode, 'local');
            assert.deepStrictEqual(snapshot.libraries.common, ['Basic/Memory/SRAM/DPRAM.v']);
            assert.deepStrictEqual(snapshot.libraries.custom, ['src/sv']);
        } finally {
            await vscode.commands.executeCommand('digital-ide.property-json.overwrite', {
                workspaceUri: vscode.Uri.file(workspacePath()),
                property: original,
                silent: true,
            });
        }
    });

    test('renders complete simulation dependencies together with design IPs, BDs and XPM primitives', async () => {
        const api = await activateExtension();
        assert.ok(api.project);
        await writeFixture(
            'sim/ip_only_tb.sv',
            'module ip_only_tb; demo u_demo(); top u_top(); endmodule\n',
        );
        await writeFixture(
            'src/sv/xpm_primitive_top.sv',
            'module xpm_primitive_top; xpm_fifo_sync u_fifo(); endmodule\n',
        );
        await writeFixture('bd/system/system.bd', '{"design":{"name":"system"}}\n');

        const snapshot = await waitFor(
            'the IP and XPM architecture entries',
            () => api.project!.refreshArchitecture(),
            value => value.modules.some(module => module.name === 'ip_only_tb')
                && value.modules.some(module => module.name === 'xpm_primitive_top')
                && value.modules.some(module => module.name === 'demo[rtl]'),
        );
        assert.ok(snapshot.modules.some(module => module.name === 'demo[rtl]'));

        const [srcRoot, simRoot] = api.project.architectureRoots();
        const ipRoot = srcRoot.children.find(node => node.name === 'demo(rtl)');
        assert.ok(ipRoot, 'the IP wrapper must remain a src root');
        assert.strictEqual(ipRoot.children.length, 0, 'generated IP implementation nodes must be hidden');
        const blockDesign = srcRoot.children.find(node => node.name === 'system');
        assert.ok(blockDesign, 'the block-design descriptor must be rendered as a design source');
        assertIcon(api.project.architectureTreeItem(blockDesign), 'bd.svg');
        const simRootNode = simRoot.children.find(node => node.name === 'ip_only_tb');
        assert.ok(simRootNode, 'the simulation-only testbench must remain below sim');
        const simIpInstance = simRootNode.children.find(node => node.name === 'demo');
        assert.ok(simIpInstance, 'the simulation hierarchy must include its design IP instance');
        assertIcon(api.project.architectureTreeItem(simIpInstance), 'ip.svg');
        const simSourceInstance = simRootNode.children.find(node => node.name === 'top');
        assert.ok(simSourceInstance, 'the simulation hierarchy must include its source dependency');
        assert.ok(
            simSourceInstance.children.some(node => node.name === 'child'),
            'the simulation hierarchy must retain transitive source dependencies',
        );

        const primitiveTop = srcRoot.children.find(node => node.name === 'xpm_primitive_top');
        assert.ok(primitiveTop);
        const primitive = primitiveTop.children.find(node => node.name === 'xpm_fifo_sync');
        assert.ok(primitive, 'the XPM primitive must remain visible in the design hierarchy');
        assertIcon(api.project.architectureTreeItem(primitive), 'cells.svg');
    });
});

function assertIcon(item: vscode.TreeItem, filename: string): void {
    const icon = item.iconPath as { light: vscode.Uri; dark: vscode.Uri };
    assert.ok(icon.light.fsPath.endsWith(path.join('images', 'svg', 'light', filename)));
    assert.ok(icon.dark.fsPath.endsWith(path.join('images', 'svg', 'dark', filename)));
}

function legacyArchitectureItemMenus(): Array<Record<string, unknown>> {
    const fileWhen = 'view == digital-ide-treeView-arch && viewItem == file';
    const fileArgument = { file: '${viewItem}' };
    return [
        {
            command: 'digital-ide.tool.icarus.simulateFile',
            group: 'inline@1',
            when: fileWhen,
            args: fileArgument,
        },
        {
            command: 'digital-ide.netlist.treeview',
            group: 'inline@3',
            when: fileWhen,
            args: fileArgument,
        },
        {
            command: 'digital-ide.pl.setSrcTop',
            group: 'navigation@1',
            when: fileWhen,
        },
        {
            command: 'digital-ide.pl.setSimTop',
            group: 'navigation@2',
            when: fileWhen,
        },
        {
            command: 'digital-ide.tool.icarus.simulateFile',
            group: 'navigation@3',
            when: fileWhen,
            args: fileArgument,
        },
        {
            command: 'digital-ide.tool.export-filelist',
            group: 'navigation@4',
            when: fileWhen,
            args: fileArgument,
        },
    ];
}
