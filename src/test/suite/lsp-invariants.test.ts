import * as assert from 'assert';
import * as vscode from 'vscode';
import {
    activateExtension,
    closeDocument,
    openFixture,
    writeFixture,
} from './helpers';

function positionIsValid(document: vscode.TextDocument, position: vscode.Position): boolean {
    return position.line >= 0
        && position.line < document.lineCount
        && position.character >= 0
        && position.character <= document.lineAt(position.line).text.length;
}

function rangeIsValid(document: vscode.TextDocument, range: vscode.Range): boolean {
    return positionIsValid(document, range.start)
        && positionIsValid(document, range.end)
        && range.start.isBeforeOrEqual(range.end);
}

function validateSymbols(
    document: vscode.TextDocument,
    symbols: readonly (vscode.DocumentSymbol | vscode.SymbolInformation)[],
): void {
    const visit = (symbol: vscode.DocumentSymbol | vscode.SymbolInformation): void => {
        assert.notStrictEqual(symbol.name.trim(), '', 'document symbol name must not be empty');
        if (symbol instanceof vscode.DocumentSymbol) {
            assert.ok(rangeIsValid(document, symbol.range), `invalid symbol range: ${symbol.name}`);
            assert.ok(
                rangeIsValid(document, symbol.selectionRange),
                `invalid symbol selection range: ${symbol.name}`,
            );
            assert.ok(
                symbol.range.contains(symbol.selectionRange),
                `selection range escapes symbol range: ${symbol.name}`,
            );
            symbol.children.forEach(visit);
            return;
        }
        if (symbol.location.uri.toString() === document.uri.toString()) {
            assert.ok(
                rangeIsValid(document, symbol.location.range),
                `invalid symbol location: ${symbol.name}`,
            );
        }
    };
    symbols.forEach(visit);
}

function completionLabel(item: vscode.CompletionItem): string {
    return typeof item.label === 'string' ? item.label : item.label.label;
}

function validateCompletions(document: vscode.TextDocument, items: readonly vscode.CompletionItem[]): void {
    for (const item of items) {
        assert.notStrictEqual(completionLabel(item).trim(), '', 'completion label must not be empty');
        // VS Code's contributed snippets use the full prefix as a synthetic replacement range,
        // which may extend past a partially typed document and is not an LSP server output.
        if (item.kind === vscode.CompletionItemKind.Snippet) {
            continue;
        }
        if (item.range instanceof vscode.Range) {
            assert.ok(
                rangeIsValid(document, item.range),
                `invalid completion range: ${completionLabel(item)} ${JSON.stringify(item.range)} in ${JSON.stringify(document.getText())}`,
            );
        } else if (item.range) {
            assert.ok(
                rangeIsValid(document, item.range.inserting),
                `invalid completion insertion range: ${completionLabel(item)} ${JSON.stringify(item.range.inserting)} in ${JSON.stringify(document.getText())}`,
            );
            assert.ok(
                rangeIsValid(document, item.range.replacing),
                `invalid completion replacement range: ${completionLabel(item)} ${JSON.stringify(item.range.replacing)} in ${JSON.stringify(document.getText())}`,
            );
        }
        for (const edit of item.additionalTextEdits ?? []) {
            assert.ok(
                rangeIsValid(document, edit.range),
                `invalid additional completion edit: ${completionLabel(item)}`,
            );
        }
    }
}

async function exercisePrefixes(relativePath: string, source: string): Promise<void> {
    await writeFixture(relativePath, '');
    const document = await openFixture(relativePath);
    const editor = vscode.window.activeTextEditor;
    assert.ok(editor && editor.document.uri.toString() === document.uri.toString());

    for (const character of source) {
        const inserted = await editor.edit(builder => {
            builder.insert(document.positionAt(document.getText().length), character);
        });
        assert.ok(inserted, `failed to insert ${JSON.stringify(character)}`);
        const position = document.positionAt(document.getText().length);
        const symbols = await vscode.commands.executeCommand<
            Array<vscode.DocumentSymbol | vscode.SymbolInformation> | undefined
        >('vscode.executeDocumentSymbolProvider', document.uri);
        validateSymbols(document, symbols ?? []);

        const completions = await vscode.commands.executeCommand<vscode.CompletionList | undefined>(
            'vscode.executeCompletionItemProvider',
            document.uri,
            position,
        );
        validateCompletions(document, completions?.items ?? []);
    }

    await closeDocument(document);
}

suite('LSP output invariants', () => {
    suiteSetup(async () => {
        await activateExtension();
    });

    test('accepts every SystemVerilog and VHDL typing prefix through VS Code', async () => {
        await exercisePrefixes(
            'src/invariants/typing.sv',
            'module top;\n  // 😀中文e\u0301\n  logic value = ;\nendmodule\n',
        );
        await exercisePrefixes(
            'src/invariants/typing.vhd',
            'entity top is\n  -- 😀中文e\u0301\n  port (clk : in std_logic);\nend entity;\n',
        );
    });
});
