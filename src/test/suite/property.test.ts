import * as assert from 'assert';
import * as fs from 'fs';
import * as path from 'path';
import * as vscode from 'vscode';
import { activateExtension } from './helpers';

function secondaryWorkspace(): string {
    const workspace = process.env.DIGITAL_TEST_SECONDARY_WORKSPACE;
    assert.ok(workspace, 'DIGITAL_TEST_SECONDARY_WORKSPACE is not set');
    return workspace;
}

function secondaryUri(): vscode.Uri {
    return vscode.Uri.file(secondaryWorkspace());
}

function propertyPath(): string {
    return path.join(secondaryWorkspace(), '.vscode', 'property.json');
}

suite('Project creation and configuration maintenance', () => {
    test('creates a complete project configuration and standard directories', async () => {
        await activateExtension();
        const response = await vscode.commands.executeCommand<{
            success: boolean;
            configGeneration: number;
        }>('digital-ide.property-json.generate', {
            workspaceUri: secondaryUri(),
            projectName: 'secondary-demo',
            toolChain: 'xilinx',
            device: 'xc7a35tftg256-1',
            silent: true,
        });
        assert.strictEqual(response.success, true);
        const property = JSON.parse(fs.readFileSync(propertyPath(), 'utf8'));
        assert.strictEqual(property.prjName.PL, 'secondary-demo');
        assert.strictEqual(property.device, 'xc7a35tftg256-1');
        for (const relative of ['user/src', 'user/sim', 'user/data', 'user/ip', 'user/bd', 'prj']) {
            assert.ok(fs.statSync(path.join(secondaryWorkspace(), relative)).isDirectory(), relative);
        }
    });

    test('atomically overwrites and canonicalizes property.json', async () => {
        const response = await vscode.commands.executeCommand<{
            success: boolean;
            changes: string[];
        }>('digital-ide.property-json.overwrite', {
            workspaceUri: secondaryUri(),
            projectName: 'overwritten-demo',
            device: 'xc7z020clg400-2',
            silent: true,
        });
        assert.strictEqual(response.success, true);
        assert.ok(response.changes.some(change => change.includes('atomically')));
        const property = JSON.parse(fs.readFileSync(propertyPath(), 'utf8'));
        assert.strictEqual(property.prjName.PL, 'overwritten-demo');
        assert.deepStrictEqual(property.files, { src: [], sim: [], exclude: [] });
    });

    test('migrates the legacy property shape', async () => {
        fs.writeFileSync(propertyPath(), JSON.stringify({
            toolchain: 'xilinx',
            projectName: 'legacy-demo',
            source: '${workspace}/rtl',
            simulation: '${workspace}/tb',
            device: 'xc7a35tftg256-1',
            soc: { core: 'none' },
        }, null, 2));
        const response = await vscode.commands.executeCommand<{
            success: boolean;
            changes: string[];
        }>('digital-ide.lsp.tool.transformOldPropertyFile', {
            workspaceUri: secondaryUri(),
            silent: true,
        });
        assert.strictEqual(response.success, true);
        assert.ok(response.changes.length >= 4);
        const property = JSON.parse(fs.readFileSync(propertyPath(), 'utf8'));
        assert.strictEqual(property.toolChain, 'xilinx');
        assert.strictEqual(property.prjName.PL, 'legacy-demo');
        assert.strictEqual(property.arch.hardware.src, '${workspace}/rtl');
        assert.strictEqual(property.arch.hardware.sim, '${workspace}/tb');
    });

    test('previews and removes only generated project content', async () => {
        fs.mkdirSync(path.join(secondaryWorkspace(), '.Xil', 'cache'), { recursive: true });
        fs.mkdirSync(path.join(secondaryWorkspace(), 'prj', 'generated'), { recursive: true });
        fs.mkdirSync(path.join(secondaryWorkspace(), 'rtl'), { recursive: true });
        fs.writeFileSync(path.join(secondaryWorkspace(), 'rtl', 'keep.sv'), 'module keep; endmodule\n');
        const preview = await vscode.commands.executeCommand<{ changes: string[] }>(
            'digital-ide.tool.clean',
            { workspaceUri: secondaryUri(), apply: false, silent: true },
        );
        assert.ok(preview.changes.some(change => change.includes('.Xil')));
        await vscode.commands.executeCommand(
            'digital-ide.tool.clean',
            { workspaceUri: secondaryUri(), apply: true, silent: true },
        );
        assert.ok(!fs.existsSync(path.join(secondaryWorkspace(), '.Xil')));
        assert.ok(!fs.existsSync(path.join(secondaryWorkspace(), 'prj')));
        assert.ok(fs.existsSync(path.join(secondaryWorkspace(), 'rtl', 'keep.sv')));
    });

    test('converts a Xilinx sources tree into the standard layout', async () => {
        const legacy = path.join(secondaryWorkspace(), 'legacy', 'demo.srcs');
        const source = path.join(legacy, 'sources_1', 'new');
        const simulation = path.join(legacy, 'sim_1', 'new');
        const constraints = path.join(legacy, 'constrs_1', 'new');
        fs.mkdirSync(source, { recursive: true });
        fs.mkdirSync(simulation, { recursive: true });
        fs.mkdirSync(constraints, { recursive: true });
        fs.writeFileSync(path.join(source, 'converted.sv'), 'module converted; endmodule\n');
        fs.writeFileSync(path.join(simulation, 'converted_tb.sv'), 'module converted_tb; endmodule\n');
        fs.writeFileSync(path.join(constraints, 'converted.xdc'), 'set_property PACKAGE_PIN A1\n');
        const response = await vscode.commands.executeCommand<{ changes: string[] }>(
            'digital-ide.structure.from-xilinx-to-standard',
            {
                workspaceUri: secondaryUri(),
                sourceRoot: path.join(secondaryWorkspace(), 'legacy'),
                apply: true,
                silent: true,
            },
        );
        assert.ok(response.changes.some(change => change.includes('converted.sv')));
        assert.ok(fs.existsSync(path.join(secondaryWorkspace(), 'user/src/converted.sv')));
        assert.ok(fs.existsSync(path.join(secondaryWorkspace(), 'user/sim/converted_tb.sv')));
        assert.ok(fs.existsSync(path.join(secondaryWorkspace(), 'user/data/converted.xdc')));
    });
});
