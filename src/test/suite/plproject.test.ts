import * as assert from 'assert';
import * as fs from 'fs';
import * as path from 'path';
import * as vscode from 'vscode';
import { activateExtension, waitFor, workspacePath, workspaceUri } from './helpers';

interface HdlParamElement {
    path: string;
    context: { modules: Record<string, unknown> };
}

suite('PL project content management', () => {
    test('maintains tops, device, and explicit project file membership through LSP', async () => {
        const api = await activateExtension();
        const propertyFile = workspaceUri('.vscode/property.json').fsPath;
        const original = JSON.parse(fs.readFileSync(propertyFile, 'utf8'));
        const managed = path.join(workspacePath(), 'extra', 'managed.sv');
        fs.mkdirSync(path.dirname(managed), { recursive: true });
        fs.writeFileSync(managed, 'module managed(input logic clk); endmodule\n');
        try {
            const srcTop = await vscode.commands.executeCommand<{ configGeneration: number }>(
                'digital-ide.pl.setSrcTop',
                { top: 'top', silent: true },
            );
            const simTop = await vscode.commands.executeCommand<{ configGeneration: number }>(
                'digital-ide.pl.setSimTop',
                { top: 'top', silent: true },
            );
            assert.ok(simTop.configGeneration >= srcTop.configGeneration);
            await vscode.commands.executeCommand('digital-ide.pl.addDevice', {
                device: 'xc7z020clg400-2',
                silent: true,
            });
            await vscode.commands.executeCommand('digital-ide.pl.addFile', {
                path: managed,
                kind: 'src',
                silent: true,
            });
            const indexed = await waitFor(
                'managed module to enter the server project',
                () => api.client.sendRequest<HdlParamElement[]>('hdlparams/request'),
                values => values.some(value => value.path === managed
                    && Object.prototype.hasOwnProperty.call(value.context.modules, 'managed')),
            );
            assert.ok(indexed.some(value => value.path === managed));

            const property = JSON.parse(fs.readFileSync(propertyFile, 'utf8'));
            assert.strictEqual(property.srcTop, 'top');
            assert.strictEqual(property.simTop, 'top');
            assert.strictEqual(property.device, 'xc7z020clg400-2');
            assert.ok(property.files.src.includes('extra/managed.sv'));

            await vscode.commands.executeCommand('digital-ide.pl.delFile', {
                path: managed,
                kind: 'src',
                silent: true,
            });
            await waitFor(
                'managed module to leave the server project',
                () => api.client.sendRequest<HdlParamElement[]>('hdlparams/request'),
                values => !values.some(value => value.path === managed),
            );
            await vscode.commands.executeCommand('digital-ide.pl.delDevice', { silent: true });
            const removed = JSON.parse(fs.readFileSync(propertyFile, 'utf8'));
            assert.strictEqual(removed.device, 'none');
            assert.ok(removed.files.exclude.includes('extra/managed.sv'));
        } finally {
            await vscode.commands.executeCommand('digital-ide.property-json.overwrite', {
                property: original,
                silent: true,
            });
        }
    });
});
