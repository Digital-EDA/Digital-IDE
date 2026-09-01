import * as assert from 'assert';
import * as vscode from 'vscode';
import { activateExtension, openFixture, workspaceUri, writeFixture } from './helpers';

suite('Editor HDL code generation', () => {
    test('generates an instance from server semantics and inserts it with WorkspaceEdit', async () => {
        await activateExtension();
        const uri = await writeFixture(
            'src/sv/instance_target.sv',
            'module instance_target;\n\nendmodule\n',
        );
        const document = await openFixture('src/sv/instance_target.sv');
        const response = await vscode.commands.executeCommand<{
            success: boolean;
            generatedText: string;
            targetVersion: number;
        }>('digital-ide.tool.instance', {
            moduleName: 'child',
            instanceName: 'u_generated_child',
            targetUri: uri,
            position: { line: 1, character: 0 },
            silent: true,
        });
        assert.strictEqual(response.success, true);
        assert.ok(response.generatedText.includes('child #('));
        assert.ok(response.generatedText.includes('.WIDTH(WIDTH)'));
        assert.ok(response.generatedText.includes('u_generated_child'));
        assert.ok(document.getText().includes('u_generated_child'));
    });

    test('rejects stale server generation and stale frontend insertion', async () => {
        const api = await activateExtension();
        const document = await openFixture('src/sv/instance_target.sv');
        const stale = await api.client.sendRequest<{
            success: boolean;
            message: string;
        }>('digital/project', {
            action: 'generateInstance',
            workspaceUri: vscode.workspace.getWorkspaceFolder(document.uri)?.uri.toString(),
            payload: {
                moduleName: 'child',
                targetUri: document.uri.toString(),
                expectedVersion: Math.max(0, document.version - 1),
            },
        });
        assert.strictEqual(stale.success, false);
        assert.ok(stale.message.includes('version changed'));

        await assert.rejects(
            async () => vscode.commands.executeCommand('digital-ide.lsp.tool.insertTextToUri', {
                    uri: workspaceUri('src/sv/instance_target.sv'),
                    text: '// stale\n',
                    expectedVersion: Math.max(0, document.version - 1),
                    position: { line: 0, character: 0 },
                }),
            /version changed/i,
        );
    });
});
