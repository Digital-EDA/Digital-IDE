import * as assert from 'assert';
import * as vscode from 'vscode';
import {
    activateExtension,
    closeDocument,
    openFixture,
    positionOf,
    waitFor,
    waitForDiagnostics,
} from './helpers';

interface SyncState {
    version?: number;
    revision?: number;
    committedRevision?: number;
    scheduledRevision?: number;
    textHash?: string;
    textBytes?: number;
    isOpen?: boolean;
    rejectedEditCount: number;
    staleParseCount: number;
    resyncCount: number;
    pendingDocuments: number;
}

interface ServerDocument {
    text: string;
    version?: number;
    textHash: string;
    textBytes: number;
    isOpen: boolean;
}

suite('Synchronization end to end', () => {
    suiteSetup(async () => {
        await activateExtension();
    });

    test('keeps VS Code, DocumentStore, diagnostics, completion, and definition on the latest edit', async () => {
        const api = await activateExtension();
        const document = await openFixture('src/sv/child.sv');
        for (let version = 0; version < 50; version += 1) {
            const text = document.getText();
            const marker = /localparam SYNC_VERSION=\d+;/.exec(text);
            const replacement = `localparam SYNC_VERSION=${version};`;
            const edit = new vscode.WorkspaceEdit();
            if (marker) {
                edit.replace(
                    document.uri,
                    new vscode.Range(
                        document.positionAt(marker.index),
                        document.positionAt(marker.index + marker[0].length),
                    ),
                    replacement,
                );
            } else {
                edit.insert(document.uri, new vscode.Position(1, 0), `  ${replacement}\n`);
            }
            assert.ok(await vscode.workspace.applyEdit(edit));
        }

        const state = await waitFor(
            'latest semantic revision',
            () => api.client.sendRequest<SyncState>('digital/debugState', {
                uri: document.uri.toString(),
            }),
            current => current.revision === current.committedRevision
                && current.revision === current.scheduledRevision,
        );
        const serverDocument = await api.client.sendRequest<ServerDocument>('digital/readDocument', {
            uri: document.uri.toString(),
        });
        assert.strictEqual(serverDocument.text, document.getText());
        assert.strictEqual(serverDocument.version, document.version);
        assert.strictEqual(serverDocument.textBytes, Buffer.byteLength(document.getText()));
        assert.strictEqual(state.rejectedEditCount, 0);

        const target = positionOf(document, 'target <=', 2);
        const completion = await vscode.commands.executeCommand<vscode.CompletionList>(
            'vscode.executeCompletionItemProvider',
            document.uri,
            target,
        );
        assert.ok(completion.items.some(item => item.label === 'target'));
        const definitions = await vscode.commands.executeCommand<Array<vscode.Location | vscode.LocationLink>>(
            'vscode.executeDefinitionProvider',
            document.uri,
            target,
        );
        assert.ok(definitions.length > 0);
        await waitForDiagnostics(document.uri, diagnostics =>
            diagnostics.every(diagnostic => !diagnostic.message.includes('SYNC_VERSION')),
        );
        await closeDocument(document);
    });

    test('automatically restores full text after an invalid LSP version', async () => {
        const api = await activateExtension();
        const document = await openFixture('src/sv/child.sv');
        api.client.sendNotification('textDocument/didChange', {
            textDocument: { uri: document.uri.toString(), version: document.version - 1 },
            contentChanges: [{ text: 'stale' }],
        });
        const state = await waitFor(
            'automatic full-text recovery',
            () => api.client.sendRequest<SyncState>('digital/debugState', {
                uri: document.uri.toString(),
            }),
            current => current.rejectedEditCount >= 1 && current.resyncCount >= 1,
        );
        assert.ok(state.rejectedEditCount >= 1);
        const serverDocument = await api.client.sendRequest<ServerDocument>('digital/readDocument', {
            uri: document.uri.toString(),
        });
        assert.strictEqual(serverDocument.text, document.getText());
        await closeDocument(document);
    });
});
