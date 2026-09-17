import * as assert from 'assert';
import * as fs from 'fs';
import * as vscode from 'vscode';
import { activateExtension, waitFor } from './helpers';

suite('Project feature surface', () => {
    test('registers every project, PL, architecture, library, and generation command', async () => {
        await activateExtension();
        const registered = new Set(await vscode.commands.getCommands(true));
        assert.ok(!registered.has('digital-ide.pl.addDevice'));
        assert.ok(!registered.has('digital-ide.pl.delDevice'));
        const expected = [
            'digital-ide.property-json.generate',
            'digital-ide.property-json.overwrite',
            'digital-ide.lsp.tool.transformOldPropertyFile',
            'digital-ide.tool.clean',
            'digital-ide.structure.from-xilinx-to-standard',
            'digital-ide.pl.setSrcTop',
            'digital-ide.pl.setSimTop',
            'digital-ide.pl.addFile',
            'digital-ide.pl.delFile',
            'digital-ide.pickLibrary',
            'digital-ide.treeView.arch.expand',
            'digital-ide.treeView.arch.collapse',
            'digital-ide.treeView.arch.refresh',
            'digital-ide.treeView.arch.openFile',
            'digital-ide.tool.instance',
            'digital-ide.lsp.tool.insertTextToUri',
            'digital-ide.tool.import-filelist',
            'digital-ide.tool.export-filelist',
            'digital-ide.tool.simulateFile',
            'digital-ide.tool.icarus.simulateFile',
            'digital-ide.netlist.show',
            'digital-ide.netlist.treeview',
        ];
        for (const command of expected) {
            assert.ok(registered.has(command), `project command was not registered: ${command}`);
        }
    });

    test('contributes and initializes all five project TreeViews', async () => {
        const api = await activateExtension();
        assert.ok(api.project, 'project extension API was not exported');
        const extension = vscode.extensions.getExtension('sterben.fpga-support');
        assert.ok(extension);
        const views = extension.packageJSON.contributes.views.TreeView as Array<{ id: string }>;
        assert.deepStrictEqual(
            views.map(view => view.id).sort(),
            [
                'digital-ide-treeView-arch',
                'digital-ide-treeView-debugger',
                'digital-ide-treeView-hardware',
                'digital-ide-treeView-software',
                'digital-ide-treeView-tool',
            ],
        );
        const snapshot = await api.project.refreshArchitecture();
        assert.ok(snapshot.files.length >= 8);
        assert.ok(snapshot.modules.some(module => module.name === 'child'));
    });

    test('opens the netlist TreeView action with the selected DesignGraph module', async function () {
        this.timeout(120_000);
        const api = await activateExtension();
        assert.ok(api.project);
        await api.project.refreshArchitecture();
        const srcRoot = api.project.architectureRoots()[0];
        const top = srcRoot.children.find(node => node.name === 'top');
        assert.ok(top, 'top module was not available for the TreeView Netlist action');
        const response = await vscode.commands.executeCommand<{
            success: boolean;
            moduleName: string;
            jsonPath: string;
            renderPath: string;
            sourceFiles: string[];
            render?: { graphs?: Array<{ quality?: { accepted?: boolean } }> };
        }>('digital-ide.netlist.treeview', { file: top });
        assert.strictEqual(response.success, true);
        assert.strictEqual(response.moduleName, 'top');
        assert.ok(response.sourceFiles.some(file => file.endsWith('top.sv')));
        assert.ok(fs.statSync(response.jsonPath).isFile());
        const netlist = JSON.parse(fs.readFileSync(response.jsonPath, 'utf8')) as {
            modules?: Record<string, unknown>;
        };
        assert.ok(netlist.modules?.top);
        assert.ok(fs.statSync(response.renderPath).isFile());
        assert.ok(response.render?.graphs?.every(graph => graph.quality?.accepted === true));
        assert.strictEqual(api.netlist?.activePanelCount, 1);
        await vscode.commands.executeCommand('workbench.action.closeActiveEditor');
        await waitFor(
            'Netlist TreeView panel disposal',
            () => api.netlist?.activePanelCount ?? 0,
            count => count === 0,
        );
    });
});
