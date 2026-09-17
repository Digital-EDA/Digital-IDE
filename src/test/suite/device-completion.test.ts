import * as assert from 'assert';
import * as fs from 'fs';
import * as os from 'os';
import * as path from 'path';
import * as vscode from 'vscode';

suite('Property device completion', () => {
    test('completes unsaved device values without writing or normalizing the property file', async () => {
        const extension = vscode.extensions.getExtension('sterben.fpga-support');
        assert.ok(extension);
        await extension.activate();
        const temporary = fs.mkdtempSync(path.join(os.tmpdir(), 'digital-device-completion-'));
        const filename = path.join(temporary, '.vscode', 'property.json');
        fs.mkdirSync(path.dirname(filename));
        const original = '{\n\t"toolChain": "xilinx",\n\t"soc": {},\n\t"device": ""\n}\n';
        fs.writeFileSync(filename, original);
        const document = await vscode.workspace.openTextDocument(vscode.Uri.file(filename));
        try {
            const complete = async (value: string, expected: string, nextStage: boolean): Promise<void> => {
                const text = document.getText();
                const start = text.indexOf('"device": "') + '"device": "'.length;
                const end = text.indexOf('"', start);
                const edit = new vscode.WorkspaceEdit();
                edit.replace(document.uri, new vscode.Range(document.positionAt(start), document.positionAt(end)), value);
                assert.ok(await vscode.workspace.applyEdit(edit));
                const response = await vscode.commands.executeCommand<vscode.CompletionList>(
                    'vscode.executeCompletionItemProvider', document.uri, document.positionAt(start + value.length),
                );
                const item = response.items.find(candidate => (typeof candidate.label === 'string'
                    ? candidate.label : candidate.label.label).startsWith(expected));
                assert.ok(item, `${value} -> ${expected}`);
                assert.ok(item.insertText instanceof vscode.SnippetString);
                assert.strictEqual(item.insertText.value, `"${expected}$0"`);
                const range = item.range as vscode.Range;
                assert.strictEqual(document.getText(range), `"${value}"`);
                assert.strictEqual(Boolean(item.command), nextStage);
                assert.strictEqual(fs.readFileSync(filename, 'utf8'), original);
            };
            await complete('', 'xc7z', true);
            await complete('xc7z', 'xc7z020', true);
            await complete('xc7z020', 'xc7z020clg400', true);
            await complete('xc7z020clg400-', 'xc7z020clg400-2', false);
            const text = document.getText();
            const offset = text.indexOf('xilinx');
            const edit = new vscode.WorkspaceEdit();
            edit.replace(document.uri, new vscode.Range(document.positionAt(offset), document.positionAt(offset + 6)), 'efinity');
            assert.ok(await vscode.workspace.applyEdit(edit));
            await complete('', 'Ti', true);
            await complete('Ti', 'Ti60', true);
            await complete('Ti60', 'Ti60F100S3F2', true);
            await complete('Ti60F100S3F2-', 'Ti60F100S3F2-C4', false);
        } finally {
            // Revert the temporary unsaved buffer before removing its file.
            const edit = new vscode.WorkspaceEdit();
            edit.replace(document.uri, new vscode.Range(document.positionAt(0), document.positionAt(document.getText().length)), original);
            await vscode.workspace.applyEdit(edit);
            fs.rmSync(temporary, { recursive: true, force: true });
        }
    });
});
