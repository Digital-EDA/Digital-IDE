import * as assert from 'assert';
import * as path from 'path';
import * as vscode from 'vscode';
import {
    activateExtension,
    closeDocument,
    openFixture,
    positionOf,
    waitFor,
    waitForDiagnostics,
    workspaceUri,
    writeFixture,
} from './helpers';

interface HdlParameterEntry {
    path: string;
    context: { modules?: Record<string, unknown> };
}

suite('Workspace lifecycle and robustness', () => {
    suiteSetup(async () => {
        await activateExtension();
    });

    test('indexes and removes files delivered through VS Code file watchers', async () => {
        const api = await activateExtension();
        const uri = await writeFixture(
            'src/sv/watched.sv',
            'module watched(input logic clk); logic value; always_ff @(posedge clk) value <= !value; endmodule\n',
        );
        const entries = await waitFor(
            'watched file to be indexed',
            () => api.client.sendRequest<HdlParameterEntry[]>('hdlparams/request'),
            current => current.some(entry => entry.path.endsWith('watched.sv')),
        );
        const watched = entries.find(entry => entry.path.endsWith('watched.sv'));
        assert.ok(watched?.context.modules && 'watched' in watched.context.modules);

        await vscode.workspace.fs.delete(uri);
        await waitFor(
            'watched file to be removed',
            () => api.client.sendRequest<HdlParameterEntry[]>('hdlparams/request'),
            current => current.every(entry => !entry.path.endsWith('watched.sv')),
        );
    });

    test('attributes include diagnostics to the header in the Extension Host', async () => {
        const headerText = 'package defs; logic duplicate; wire duplicate; endpackage\n';
        await writeFixture('src/sv/defs.svh', headerText);
        const header = await openFixture('src/sv/defs.svh');
        const diagnostics = await waitForDiagnostics(
            header.uri,
            current => current.some(diagnostic => diagnostic.source === 'Digital-IDE'),
        );
        assert.ok(diagnostics.every(diagnostic => diagnostic.source === 'Digital-IDE'));
        await closeDocument(header);
    });

    test('recovers from malformed source and keeps providers responsive', async () => {
        const malformed = await openFixture('src/sv/malformed.sv');
        const diagnostics = await waitForDiagnostics(
            malformed.uri,
            current => current.some(diagnostic => diagnostic.source === 'Digital-IDE'),
        );
        assert.ok(diagnostics.every(diagnostic => diagnostic.source === 'Digital-IDE'));
        assert.ok(diagnostics.some(diagnostic => diagnostic.severity === vscode.DiagnosticSeverity.Error));
        await closeDocument(malformed);

        const healthy = await openFixture('src/sv/child.sv');
        const completion = await vscode.commands.executeCommand<vscode.CompletionList>(
            'vscode.executeCompletionItemProvider',
            healthy.uri,
            positionOf(healthy, 'target <=', 2),
        );
        assert.ok(completion.items.some(item => item.label === 'target'));
        await closeDocument(healthy);
    });

    test('serves concurrent provider requests and remains responsive after cancellation', async () => {
        const api = await activateExtension();
        const document = await openFixture('src/sv/child.sv');
        const position = positionOf(document, 'target <=', 2);
        const requests = Array.from({ length: 8 }, (_, index) => index % 2 === 0
            ? vscode.commands.executeCommand<vscode.CompletionList>(
                'vscode.executeCompletionItemProvider',
                document.uri,
                position,
            )
            : vscode.commands.executeCommand<vscode.Hover[]>(
                'vscode.executeHoverProvider',
                document.uri,
                position,
            ));
        const responses = await Promise.all(requests);
        assert.ok(responses.every(response => response !== undefined));

        const cancellation = new vscode.CancellationTokenSource();
        cancellation.cancel();
        await api.client.sendRequest(
            'textDocument/completion',
            {
                textDocument: { uri: document.uri.toString() },
                position: { line: position.line, character: position.character },
                context: { triggerKind: 1 },
            },
            cancellation.token,
        ).catch(() => undefined);

        const definitions = await vscode.commands.executeCommand<Array<vscode.Location | vscode.LocationLink>>(
            'vscode.executeDefinitionProvider',
            document.uri,
            position,
        );
        assert.ok(definitions.length > 0);
        await closeDocument(document);
    });

    test('survives workspace folder notifications without losing the active project', async function () {
        this.timeout(180_000);
        const api = await activateExtension();
        const extra = workspaceUri('../secondary-workspace');
        const existingIndex = vscode.workspace.workspaceFolders?.findIndex(
            folder => folder.uri.toString() === extra.toString(),
        ) ?? -1;
        assert.ok(existingIndex >= 0, 'secondary workspace folder was not registered');
        const expectedRootsAfterRemoval =
            (vscode.workspace.workspaceFolders?.length ?? 0) - 1;
        const initiallyRemoved = new Promise<void>(resolve => {
            const subscription = vscode.workspace.onDidChangeWorkspaceFolders(event => {
                if (event.removed.some(folder => folder.uri.toString() === extra.toString())) {
                    subscription.dispose();
                    resolve();
                }
            });
        });
        assert.ok(vscode.workspace.updateWorkspaceFolders(existingIndex, 1));
        await initiallyRemoved;
        await waitFor(
            'secondary workspace removal to reach the server',
            () => api.client.sendRequest<{ workspaceRoots: string[] }>('digital/debugState', {}),
            state => state.workspaceRoots.length === expectedRootsAfterRemoval,
            60_000,
        );

        const extraSource = await configuredSourceUri(extra, 'extra.sv');
        await vscode.workspace.fs.createDirectory(vscode.Uri.file(path.dirname(extraSource.fsPath)));
        await vscode.workspace.fs.writeFile(
            extraSource,
            Buffer.from('module electron_extra_root; endmodule\n'),
        );
        const before = vscode.workspace.workspaceFolders?.length ?? 0;
        const added = new Promise<void>(resolve => {
            const subscription = vscode.workspace.onDidChangeWorkspaceFolders(event => {
                if (event.added.some(folder => folder.uri.toString() === extra.toString())) {
                    subscription.dispose();
                    resolve();
                }
            });
        });
        assert.ok(vscode.workspace.updateWorkspaceFolders(before, 0, { uri: extra, name: 'extra' }));
        await added;
        await waitFor(
            'secondary workspace addition to reach the server',
            () => api.client.sendRequest<{ workspaceRoots: string[] }>('digital/debugState', {}),
            state => state.workspaceRoots.some(root => root === extra.fsPath),
            60_000,
        );

        const symbols = await waitFor(
            'extra workspace symbols',
            () => Promise.resolve(vscode.commands.executeCommand<vscode.SymbolInformation[]>(
                'vscode.executeWorkspaceSymbolProvider',
                'electron_extra_root',
            )),
            current => current.some(symbol => symbol.name === 'electron_extra_root'
                && symbol.location.uri.toString() === extraSource.toString()),
            60_000,
        );
        assert.ok(symbols.some(symbol => symbol.name === 'electron_extra_root'));

        const document = await openFixture('src/sv/child.sv');
        const hover = await vscode.commands.executeCommand<vscode.Hover[]>(
            'vscode.executeHoverProvider',
            document.uri,
            positionOf(document, 'target <=', 2),
        );
        assert.ok(hover.length > 0);
        await closeDocument(document);

        const extraIndex = vscode.workspace.workspaceFolders?.findIndex(
            folder => folder.uri.toString() === extra.toString(),
        ) ?? -1;
        assert.ok(extraIndex >= 0, 'extra workspace folder was not registered');
        const removed = new Promise<void>(resolve => {
            const subscription = vscode.workspace.onDidChangeWorkspaceFolders(event => {
                if (event.removed.some(folder => folder.uri.toString() === extra.toString())) {
                    subscription.dispose();
                    resolve();
                }
            });
        });
        assert.ok(vscode.workspace.updateWorkspaceFolders(extraIndex, 1));
        await removed;
        await waitFor(
            'extra workspace symbols to be removed',
            () => Promise.resolve(vscode.commands.executeCommand<vscode.SymbolInformation[]>(
                'vscode.executeWorkspaceSymbolProvider',
                'electron_extra_root',
            )),
            current => current.every(symbol => symbol.name !== 'electron_extra_root'),
            60_000,
        );
    });
});

async function configuredSourceUri(workspace: vscode.Uri, fileName: string): Promise<vscode.Uri> {
    const propertyUri = vscode.Uri.joinPath(workspace, '.vscode', 'property.json');
    try {
        const property = JSON.parse(Buffer.from(await vscode.workspace.fs.readFile(propertyUri)).toString());
        const configured = property?.arch?.hardware?.src;
        if (typeof configured === 'string' && configured.trim()) {
            const expanded = configured.replaceAll('${workspace}', workspace.fsPath);
            const sourceRoot = path.isAbsolute(expanded)
                ? expanded
                : path.join(workspace.fsPath, expanded);
            return vscode.Uri.file(path.join(sourceRoot, fileName));
        }
    } catch {
        // A workspace without property.json uses the server's standard source directory.
    }
    return vscode.Uri.joinPath(workspace, 'user', 'src', fileName);
}
