import * as assert from 'assert';
import * as vscode from 'vscode';
import {
    activateExtension,
    closeDocument,
    flattenDocumentSymbols,
    openFixture,
    positionOf,
    replaceText,
    waitForDiagnostics,
} from './helpers';

suite('VHDL desktop LSP', () => {
    suiteSetup(async () => {
        await activateExtension();
    });

    test('runs completion, definition, highlight, hover, and symbol providers', async () => {
        const document = await openFixture('src/vhdl/top.vhd');
        await waitForDiagnostics(document.uri, diagnostics => diagnostics.length === 0);
        const targetUse = positionOf(document, 'output_signal <= target', 'output_signal <= tar'.length);

        const completion = await vscode.commands.executeCommand<vscode.CompletionList>(
            'vscode.executeCompletionItemProvider',
            document.uri,
            targetUse,
        );
        assert.ok(completion.items.some(item => item.label.toString().toLowerCase() === 'target'));

        const definitions = await vscode.commands.executeCommand<Array<vscode.Location | vscode.LocationLink>>(
            'vscode.executeDefinitionProvider',
            document.uri,
            positionOf(document, 'architecture rtl of top_vhdl', 'architecture rtl of top_vh'.length),
        );
        assert.ok(definitions.length > 0);

        const highlights = await vscode.commands.executeCommand<vscode.DocumentHighlight[]>(
            'vscode.executeDocumentHighlights',
            document.uri,
            targetUse,
        );
        assert.ok(highlights.length >= 3);

        const hoverPositions = [
            targetUse,
            positionOf(document, 'signal target', 'signal tar'.length),
        ];
        for (const hoverPosition of hoverPositions) {
            const hovers = await vscode.commands.executeCommand<vscode.Hover[]>(
                'vscode.executeHoverProvider',
                document.uri,
                hoverPosition,
            );
            assert.ok(
                hovers.some(hover => hover.contents.some(content => (
                    typeof content === 'string' ? content : content.value
                ).includes('signal target'))),
                `VHDL hover contents: ${JSON.stringify(hovers)}`,
            );
            const tokenRange = document.getWordRangeAtPosition(hoverPosition);
            assert.ok(tokenRange, 'VHDL hover position did not resolve to an identifier');
            assert.ok(
                hovers.some(hover => hover.range?.isEqual(tokenRange)),
                `VHDL hover ranges: ${JSON.stringify(hovers.map(hover => hover.range))}`,
            );
        }

        const symbols = await vscode.commands.executeCommand<Array<vscode.DocumentSymbol | vscode.SymbolInformation>>(
            'vscode.executeDocumentSymbolProvider',
            document.uri,
        );
        const names = flattenDocumentSymbols(symbols).map(name => name.toLowerCase());
        assert.ok(
            names.some(name => name.includes('top_vhdl')),
            `VHDL symbols: ${names.join(', ')}`,
        );
        assert.ok(
            names.some(name => name.includes("architecture 'rtl'")),
            `VHDL symbols: ${names.join(', ')}`,
        );

        const codeLenses = await vscode.commands.executeCommand<vscode.CodeLens[]>(
            'vscode.executeCodeLensProvider',
            document.uri,
        );
        assert.deepStrictEqual(codeLenses, []);
        const inlayHints = await vscode.commands.executeCommand<vscode.InlayHint[]>(
            'vscode.executeInlayHintProvider',
            document.uri,
            new vscode.Range(new vscode.Position(0, 0), document.lineAt(document.lineCount - 1).range.end),
        );
        assert.deepStrictEqual(inlayHints, []);
        await closeDocument(document);
    });

    test('returns formatter edits without mutating the file behind VS Code', async () => {
        const document = await openFixture('src/vhdl/format.vhd');
        const original = document.getText();
        const edits = await vscode.commands.executeCommand<vscode.TextEdit[]>(
            'vscode.executeFormatDocumentProvider',
            document.uri,
            { tabSize: 4, insertSpaces: true },
        );
        assert.ok(edits.length > 0, 'VHDL formatter returned no edits for an unformatted file');
        assert.strictEqual(document.getText(), original, 'server mutated the document before edits were applied');

        const workspaceEdit = new vscode.WorkspaceEdit();
        workspaceEdit.set(document.uri, edits);
        assert.ok(await vscode.workspace.applyEdit(workspaceEdit));
        assert.notStrictEqual(document.getText(), original);
        assert.ok(document.getText().includes('architecture rtl of format_vhdl is'));
        assert.ok(await document.save());
        await closeDocument(document);
    });

    test('runs references, rename, workspace symbols, and call hierarchy providers', async () => {
        const api = await activateExtension();
        const document = await openFixture('src/vhdl/top.vhd');
        const target = positionOf(document, 'target <=', 2);
        const references = await vscode.commands.executeCommand<vscode.Location[]>(
            'vscode.executeReferenceProvider',
            document.uri,
            target,
        );
        assert.ok(references.length >= 3, `VHDL references: ${JSON.stringify(references)}`);
        const preparedRename = await api.client.sendRequest<{ placeholder: string } | null>(
            'textDocument/prepareRename',
            {
                textDocument: { uri: document.uri.toString() },
                position: { line: target.line, character: target.character },
            },
        );
        assert.strictEqual(preparedRename?.placeholder.toLowerCase(), 'target');
        const rawRename = await api.client.sendRequest<{ changes?: Record<string, vscode.TextEdit[]> } | null>(
            'textDocument/rename',
            {
                textDocument: { uri: document.uri.toString() },
                position: { line: target.line, character: target.character },
                newName: 'renamed_target',
            },
        );
        assert.ok((rawRename?.changes?.[document.uri.toString()]?.length ?? 0) >= 3,
            `raw VHDL rename response: ${JSON.stringify(rawRename)}`);
        const rename = await vscode.commands.executeCommand<vscode.WorkspaceEdit>(
            'vscode.executeDocumentRenameProvider',
            document.uri,
            target,
            'renamed_target',
        );
        const edits = rename.entries().find(([uri]) => uri.toString() === document.uri.toString())?.[1] ?? [];
        assert.ok(edits.length >= 3, `VHDL rename edits: ${JSON.stringify(rename.entries())}`);
        const symbols = await vscode.commands.executeCommand<vscode.SymbolInformation[]>(
            'vscode.executeWorkspaceSymbolProvider',
            'top_vhdl',
        );
        assert.ok(symbols.some(symbol => symbol.name.toLowerCase() === 'top_vhdl'));
        await closeDocument(document);

        const child = await openFixture('src/vhdl/call_child.vhd');
        const prepared = await vscode.commands.executeCommand<vscode.CallHierarchyItem[]>(
            'vscode.prepareCallHierarchy',
            child.uri,
            positionOf(child, 'call_child', 2),
        );
        const childItem = prepared.find(item => item.name.toLowerCase() === 'call_child');
        assert.ok(childItem, `VHDL call roots: ${JSON.stringify(prepared)}`);
        const incoming = await vscode.commands.executeCommand<vscode.CallHierarchyIncomingCall[]>(
            'vscode.provideIncomingCalls',
            childItem,
        );
        assert.ok(incoming.some(call => call.from.name.toLowerCase() === 'call_top'));
        const outgoing = await vscode.commands.executeCommand<vscode.CallHierarchyOutgoingCall[]>(
            'vscode.provideOutgoingCalls',
            childItem,
        );
        assert.ok(outgoing.some(call => call.to.name.toLowerCase() === 'call_leaf'));
        await closeDocument(child);
    });

    test('publishes and clears semantic diagnostics after an incremental edit', async () => {
        const document = await openFixture('src/vhdl/invalid.vhd');
        const diagnostics = await waitForDiagnostics(
            document.uri,
            current => current.some(diagnostic => diagnostic.message.includes('missing_signal')),
        );
        assert.ok(diagnostics.some(diagnostic => diagnostic.source === 'Digital-IDE'));

        await replaceText(document, 'missing_signal', 'target');
        await waitForDiagnostics(
            document.uri,
            current => current.every(diagnostic => !diagnostic.message.includes('missing_signal')),
            'VHDL diagnostic to clear after didChange',
        );
        assert.ok(await document.save());
        await closeDocument(document);
    });
});
