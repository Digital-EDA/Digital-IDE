import * as assert from 'assert';
import * as vscode from 'vscode';
import {
    activateExtension,
    closeDocument,
    completionLabel,
    flattenDocumentSymbols,
    openFixture,
    positionOf,
    replaceText,
    waitFor,
    waitForDiagnostics,
    writeFixture,
} from './helpers';

function completionInsertText(item: vscode.CompletionItem): string | undefined {
    return typeof item.insertText === 'string'
        ? item.insertText
        : item.insertText?.value;
}

interface SemanticTokensResponse {
    resultId?: string;
    data?: number[];
    edits?: Array<{ start: number; deleteCount: number; data?: number[] }>;
}

interface DecodedSemanticToken {
    line: number;
    start: number;
    length: number;
    tokenType: number;
    modifiers: number;
}

function decodeSemanticTokens(data: number[]): DecodedSemanticToken[] {
    assert.strictEqual(data.length % 5, 0, `invalid semantic token data: ${data.join(',')}`);
    const result: DecodedSemanticToken[] = [];
    let line = 0;
    let start = 0;
    for (let index = 0; index < data.length; index += 5) {
        line += data[index];
        start = data[index] === 0 ? start + data[index + 1] : data[index + 1];
        result.push({
            line,
            start,
            length: data[index + 2],
            tokenType: data[index + 3],
            modifiers: data[index + 4],
        });
    }
    return result;
}

function inlayHintLabel(hint: vscode.InlayHint): string {
    return typeof hint.label === 'string'
        ? hint.label
        : hint.label.map(part => part.value).join('');
}

suite('SystemVerilog desktop LSP', () => {
    suiteSetup(async () => {
        await activateExtension();
    });

    test('automatically accepts a local symbol after identifier typing', async () => {
        await writeFixture(
            'src/sv/automatic_completion.v',
            [
                'module automatic_completion;',
                '    reg [31:0] register [31:0];',
                '    initial begin',
                '        ',
                '    end',
                'endmodule',
                '',
            ].join('\n'),
        );
        const document = await openFixture('src/sv/automatic_completion.v');
        const editor = vscode.window.activeTextEditor;
        assert.ok(editor);

        const quickSuggestions = vscode.workspace
            .getConfiguration('editor', document)
            .get<Record<string, string>>('quickSuggestions');
        assert.strictEqual(quickSuggestions?.other, 'on');

        const insertion = new vscode.Position(3, 8);
        editor.selection = new vscode.Selection(insertion, insertion);
        await vscode.commands.executeCommand('workbench.action.focusActiveEditorGroup');
        await vscode.commands.executeCommand('type', { text: 're' });
        await new Promise(resolve => setTimeout(resolve, 1500));
        await vscode.commands.executeCommand('acceptSelectedSuggestion');

        await waitFor(
            'automatic register completion',
            () => document.lineAt(3).text.trim(),
            line => line === 'register',
        );
        await vscode.commands.executeCommand('workbench.action.files.revert');
        await closeDocument(document);
    });

    test('orders complete module snippets after visible symbols and completes package imports', async () => {
        const document = await openFixture('src/sv/completion_package.sv');
        const localCompletion = await vscode.commands.executeCommand<vscode.CompletionList>(
            'vscode.executeCompletionItemProvider',
            document.uri,
            positionOf(document, 'sink = chi;', 'sink = chi'.length),
        );
        const childItems = localCompletion.items.filter(
            item => completionLabel(item) === 'child',
        );
        const localSymbol = childItems.find(item => item.sortText === '0');
        const moduleSnippet = childItems.find(
            item => item.sortText === '2' && item.insertText instanceof vscode.SnippetString,
        );
        assert.ok(localSymbol, `child completions: ${JSON.stringify(childItems)}`);
        assert.ok(moduleSnippet, `child completions: ${JSON.stringify(childItems)}`);
        assert.ok(
            localCompletion.items.indexOf(localSymbol) < localCompletion.items.indexOf(moduleSnippet),
            'the module snippet was not sorted after the current-file symbol',
        );
        const snippet = completionInsertText(moduleSnippet);
        assert.ok(snippet?.startsWith('child #('), `module snippet: ${snippet}`);
        assert.ok(snippet?.includes('.WIDTH(${2:WIDTH})'), `module snippet: ${snippet}`);
        assert.ok(snippet?.includes('${1:u_child}'), `module snippet: ${snippet}`);
        assert.ok(snippet?.includes('.clk(${3:clk})'), `module snippet: ${snippet}`);
        assert.ok(snippet?.includes('.out(${4:out})'), `module snippet: ${snippet}`);

        const wildcardCompletion = await vscode.commands.executeCommand<vscode.CompletionList>(
            'vscode.executeCompletionItemProvider',
            document.uri,
            positionOf(document, 'sink = IMP;', 'sink = IMP'.length),
        );
        const wildcardLabels = wildcardCompletion.items.map(completionLabel);
        for (const name of ['IMPORTED_WIDTH', 'imported_word_t', 'imported_ready']) {
            const item = wildcardCompletion.items.find(candidate => completionLabel(candidate) === name);
            assert.ok(item, `wildcard package completions: ${wildcardLabels.join(', ')}`);
            assert.strictEqual(item.sortText, '1');
        }

        const namedCompletion = await vscode.commands.executeCommand<vscode.CompletionList>(
            'vscode.executeCompletionItemProvider',
            document.uri,
            positionOf(document, 'sink = IMP;', 'sink = IMP'.length, true),
        );
        const namedLabels = namedCompletion.items.map(completionLabel);
        assert.ok(namedLabels.includes('IMPORTED_WIDTH'), `named import: ${namedLabels.join(', ')}`);
        assert.ok(!namedLabels.includes('imported_word_t'), `named import: ${namedLabels.join(', ')}`);
        assert.ok(!namedLabels.includes('imported_ready'), `named import: ${namedLabels.join(', ')}`);
        await closeDocument(document);
    });

    test('completes every parameter or port in the matching instance region', async () => {
        const document = await openFixture('src/sv/top.sv');
        const parameters = await vscode.commands.executeCommand<vscode.CompletionList>(
            'vscode.executeCompletionItemProvider',
            document.uri,
            positionOf(document, '.WIDTH', 1),
            '.',
        );
        const parameterLabels = parameters.items.map(completionLabel);
        assert.ok(parameterLabels.includes('WIDTH'), `parameter completions: ${parameterLabels.join(', ')}`);
        assert.ok(!parameterLabels.includes('clk'), `parameter completions: ${parameterLabels.join(', ')}`);
        assert.ok(!parameterLabels.includes('out'), `parameter completions: ${parameterLabels.join(', ')}`);

        const ports = await vscode.commands.executeCommand<vscode.CompletionList>(
            'vscode.executeCompletionItemProvider',
            document.uri,
            positionOf(document, '.clk', 1),
            '.',
        );
        const portLabels = ports.items.map(completionLabel);
        assert.ok(portLabels.includes('clk'), `port completions: ${portLabels.join(', ')}`);
        assert.ok(portLabels.includes('out'), `port completions: ${portLabels.join(', ')}`);
        assert.ok(!portLabels.includes('WIDTH'), `port completions: ${portLabels.join(', ')}`);
        await closeDocument(document);
    });

    test('uses the packaged Xilinx primitive catalog for diagnostics and instantiation completion', async () => {
        await writeFixture(
            'src/sv/xilinx_primitive_catalog.sv',
            [
                'module xilinx_primitive_catalog;',
                '  logic clk, dout;',
                '  xpm_fifo_sync #(',
                '    .FIFO_WRITE_DEPTH(16)',
                '  ) u_fifo (',
                '    .dout(dout),',
                '    .rd_rst_busy(),',
                "    .rst(1'b0),",
                '    .wr_clk(clk),',
                "    .wr_en(1'b0)",
                '  );',
                '  missing_block u_missing();',
                'endmodule',
                '',
            ].join('\n'),
        );
        const document = await openFixture('src/sv/xilinx_primitive_catalog.sv');
        const diagnostics = await waitForDiagnostics(
            document.uri,
            current => current.some(diagnostic => String(diagnostic.code) === 'UnknownModule'
                && diagnostic.message.includes('missing_block')),
        );
        assert.ok(diagnostics.every(diagnostic => String(diagnostic.code) !== 'UnknownModule'
            || !diagnostic.message.includes('xpm_fifo_sync')));

        const modules = await vscode.commands.executeCommand<vscode.CompletionList>(
            'vscode.executeCompletionItemProvider',
            document.uri,
            positionOf(document, 'xpm_fifo_sync', 'xpm_fifo_sync'.length),
        );
        const primitive = modules.items.find(item =>
            completionLabel(item) === 'xpm_fifo_sync'
                && item.detail === 'instantiate Xilinx primitive xpm_fifo_sync');
        assert.ok(primitive, `primitive completions: ${modules.items.map(completionLabel).join(', ')}`);
        const snippet = completionInsertText(primitive);
        assert.ok(snippet?.includes('.FIFO_WRITE_DEPTH'));
        assert.ok(snippet?.includes('.wr_en'));

        const ports = await vscode.commands.executeCommand<vscode.CompletionList>(
            'vscode.executeCompletionItemProvider',
            document.uri,
            positionOf(document, '.wr_en', 1),
            '.',
        );
        const portLabels = ports.items.map(completionLabel);
        assert.ok(portLabels.includes('wr_en'), `primitive ports: ${portLabels.join(', ')}`);
        assert.ok(portLabels.includes('wr_clk'), `primitive ports: ${portLabels.join(', ')}`);

        const api = await activateExtension();
        const provider = api.client.initializeResult?.capabilities.semanticTokensProvider;
        assert.ok(provider && typeof provider === 'object' && 'legend' in provider);
        const semantic = await api.client.sendRequest<SemanticTokensResponse | null>(
            'textDocument/semanticTokens/full',
            { textDocument: { uri: document.uri.toString() } },
        );
        const namedDout = positionOf(document, '.dout', 1);
        const outputToken = decodeSemanticTokens(semantic?.data ?? []).find(token =>
            token.line === namedDout.line && token.start === namedDout.character);
        assert.ok(outputToken, `primitive semantic tokens: ${JSON.stringify(semantic)}`);
        assert.strictEqual(provider.legend.tokenTypes[outputToken.tokenType], 'parameter');
        assert.ok(provider.legend.tokenModifiers.filter(
            (_, index) => (outputToken.modifiers & (1 << index)) !== 0,
        ).includes('write'));
        for (const [member, length] of [
            ['.rd_rst_busy', 11],
            ['.rst', 3],
            ['.wr_clk', 6],
        ] as const) {
            const position = positionOf(document, member, 1);
            const token = decodeSemanticTokens(semantic?.data ?? []).find(candidate =>
                candidate.line === position.line
                    && candidate.start === position.character
                    && candidate.length === length);
            assert.ok(token, `missing semantic token for ${member}`);
            assert.strictEqual(provider.legend.tokenTypes[token.tokenType], 'parameter');
        }

        const moduleHovers = await vscode.commands.executeCommand<vscode.Hover[]>(
            'vscode.executeHoverProvider',
            document.uri,
            positionOf(document, 'xpm_fifo_sync', 2),
        );
        const moduleHoverText = moduleHovers
            .flatMap(hover => hover.contents)
            .map(content => typeof content === 'string' ? content : content.value)
            .join('\n');
        assert.ok(moduleHoverText.includes('Xilinx primitive'));
        assert.ok(moduleHoverText.includes('module xpm_fifo_sync'));

        const portHovers = await vscode.commands.executeCommand<vscode.Hover[]>(
            'vscode.executeHoverProvider',
            document.uri,
            positionOf(document, '.dout', 2),
        );
        const portHoverText = portHovers
            .flatMap(hover => hover.contents)
            .map(content => typeof content === 'string' ? content : content.value)
            .join('\n');
        assert.ok(portHoverText.includes('output wire dout'));
        assert.ok(portHoverText.includes('Read Data'));

        const hints = await vscode.commands.executeCommand<vscode.InlayHint[]>(
            'vscode.executeInlayHintProvider',
            document.uri,
            new vscode.Range(document.positionAt(0), document.positionAt(document.getText().length)),
        );
        const hintLabels = hints.map(inlayHintLabel);
        assert.strictEqual(hintLabels.filter(label => label === '→').length, 2);
        assert.strictEqual(hintLabels.filter(label => label === '←').length, 3);
        await closeDocument(document);
    });

    test('recognizes indexed VHDL XCI wrappers as mixed-language IP modules', async () => {
        await writeFixture(
            'sim/sv_xci_ip.sv',
            [
                'module sv_xci_ip;',
                '  demo u_demo();',
                '  missing_xci_module u_missing();',
                'endmodule',
                '',
            ].join('\n'),
        );
        const document = await openFixture('sim/sv_xci_ip.sv');
        const diagnostics = await waitForDiagnostics(
            document.uri,
            current => current.some(diagnostic => String(diagnostic.code) === 'UnknownModule'
                && diagnostic.message.includes('missing_xci_module')),
        );
        assert.ok(diagnostics.every(diagnostic => String(diagnostic.code) !== 'UnknownModule'
            || !diagnostic.message.includes('demo')));

        const modules = await vscode.commands.executeCommand<vscode.CompletionList>(
            'vscode.executeCompletionItemProvider',
            document.uri,
            positionOf(document, 'demo', 'demo'.length),
        );
        assert.ok(modules.items.some(item => completionLabel(item) === 'demo'));

        const hovers = await vscode.commands.executeCommand<vscode.Hover[]>(
            'vscode.executeHoverProvider',
            document.uri,
            positionOf(document, 'demo', 2),
        );
        const hoverText = hovers
            .flatMap(hover => hover.contents)
            .map(content => typeof content === 'string' ? content : content.value)
            .join('\n');
        assert.ok(hoverText.includes('demo'));
        await closeDocument(document);
    });

    test('provides Vide-compatible full, delta, and range semantic tokens', async () => {
        await writeFixture(
            'src/sv/semantic_tokens.sv',
            [
                '`define BUS_WIDTH 8',
                'module semantic_child #(',
                '    parameter BUS_WIDTH = `BUS_WIDTH',
                ') (',
                '    input logic clk,',
                '    input logic reset_n,',
                '    output logic data_o',
                ');',
                '    typedef logic [BUS_WIDTH-1:0] word_t;',
                'endmodule',
                '',
                'module semantic_top;',
                '    logic clk, reset_n, data;',
                '    semantic_child #(.BUS_WIDTH(`BUS_WIDTH)) u_child (',
                '        .clk(clk), .reset_n(reset_n), .data_o(data)',
                '    );',
                'endmodule',
                '',
            ].join('\n'),
        );
        const document = await openFixture('src/sv/semantic_tokens.sv');
        const api = await activateExtension();
        const provider = api.client.initializeResult?.capabilities.semanticTokensProvider;
        assert.ok(provider && typeof provider === 'object' && 'legend' in provider);
        const tokenTypes = provider.legend.tokenTypes;
        const tokenModifiers = provider.legend.tokenModifiers;

        const full = await api.client.sendRequest<SemanticTokensResponse | null>(
            'textDocument/semanticTokens/full',
            { textDocument: { uri: document.uri.toString() } },
        );
        assert.ok(full?.resultId);
        assert.ok(full.data?.length);
        const decoded = decodeSemanticTokens(full.data ?? []);
        const classified = decoded.map(token => ({
            text: document.getText(new vscode.Range(
                token.line,
                token.start,
                token.line,
                token.start + token.length,
            )),
            type: tokenTypes[token.tokenType],
            modifiers: tokenModifiers.filter((_, index) => (token.modifiers & (1 << index)) !== 0),
        }));
        assert.ok(classified.some(token => token.text === 'clk'
            && token.type === 'keyword'
            && token.modifiers.includes('read')));
        assert.ok(classified.some(token => token.text === 'reset_n'
            && token.type === 'property'));
        assert.ok(classified.some(token => token.text === 'data_o'
            && token.type === 'parameter'
            && token.modifiers.includes('write')));
        assert.ok(classified.some(token => token.text === 'u_child'
            && token.type === 'variable'));
        assert.ok(classified.some(token => token.text === 'word_t'
            && token.type === 'type'));
        assert.ok(classified.some(token => token.text === 'BUS_WIDTH'
            && token.type === 'macro'));

        const delta = await api.client.sendRequest<SemanticTokensResponse | null>(
            'textDocument/semanticTokens/full/delta',
            {
                textDocument: { uri: document.uri.toString() },
                previousResultId: full.resultId,
            },
        );
        assert.strictEqual(delta?.resultId, full.resultId);
        assert.deepStrictEqual(delta?.edits, []);

        const range = new vscode.Range(13, 0, 16, 0);
        const ranged = await api.client.sendRequest<SemanticTokensResponse | null>(
            'textDocument/semanticTokens/range',
            {
                textDocument: { uri: document.uri.toString() },
                range,
            },
        );
        const rangedTokens = decodeSemanticTokens(ranged?.data ?? []);
        assert.ok(rangedTokens.length > 0);
        assert.ok(rangedTokens.every(token => token.line >= 13 && token.line < 16));
        await closeDocument(document);
    });

    test('completes unsaved include paths from configured include directories', async () => {
        const document = await openFixture('src/sv/include_completion.sv');
        try {
            await replaceText(document, '`include "unused"', '`include "comp');
            const files = await vscode.commands.executeCommand<vscode.CompletionList>(
                'vscode.executeCompletionItemProvider',
                document.uri,
                positionOf(document, '`include "comp', '`include "comp'.length),
                '"',
            );
            const includeFile = files.items.find(
                item => completionLabel(item) === 'completion_defs.svh',
            );
            assert.ok(includeFile, `include files: ${files.items.map(completionLabel).join(', ')}`);
            assert.strictEqual(includeFile.kind, vscode.CompletionItemKind.File);
            assert.strictEqual(completionInsertText(includeFile), 'completion_defs.svh');

            await vscode.commands.executeCommand('workbench.action.files.revert');
            await replaceText(document, '`include "unused"', '`include "');
            const directories = await vscode.commands.executeCommand<vscode.CompletionList>(
                'vscode.executeCompletionItemProvider',
                document.uri,
                positionOf(document, '`include "', '`include "'.length),
                '"',
            );
            const nestedDirectory = directories.items.find(
                item => completionLabel(item) === 'nested',
            );
            assert.ok(
                nestedDirectory,
                `include directories: ${directories.items.map(completionLabel).join(', ')}`,
            );
            assert.strictEqual(nestedDirectory.kind, vscode.CompletionItemKind.Folder);
            assert.strictEqual(completionInsertText(nestedDirectory), 'nested/');

            await vscode.commands.executeCommand('workbench.action.files.revert');
            await replaceText(document, '`include "unused"', '`include "nested/ne');
            const nestedFiles = await vscode.commands.executeCommand<vscode.CompletionList>(
                'vscode.executeCompletionItemProvider',
                document.uri,
                positionOf(document, '`include "nested/ne', '`include "nested/ne'.length),
                '/',
            );
            const nestedFile = nestedFiles.items.find(
                item => completionLabel(item) === 'nested_defs.svh',
            );
            assert.ok(
                nestedFile,
                `nested include files: ${nestedFiles.items.map(completionLabel).join(', ')}`,
            );
            assert.strictEqual(completionInsertText(nestedFile), 'nested_defs.svh');
        } finally {
            await vscode.commands.executeCommand('workbench.action.files.revert');
            await closeDocument(document);
        }
    });

    test('provides Vide-compatible module connection and parameter inlay hints', async () => {
        await writeFixture(
            'src/sv/inlay_instantiation.sv',
            [
                'module inlay_child #(',
                '  parameter WIDTH = 1,',
                '  parameter DEPTH = 2',
                ') (input i, output o, inout io, ref r);',
                'endmodule',
                'module inlay_top;',
                '  logic a, b, c, d;',
                '  inlay_child #(4, 8) ordered(a, b, c, d);',
                '  inlay_child named(.i(a), .o(b), .io(c), .r(d));',
                'endmodule',
                '',
            ].join('\n'),
        );
        const document = await openFixture('src/sv/inlay_instantiation.sv');
        const orderedLine = document.lineAt(7);
        const hints = await vscode.commands.executeCommand<vscode.InlayHint[]>(
            'vscode.executeInlayHintProvider',
            document.uri,
            orderedLine.range,
        );
        const labels = hints.map(inlayHintLabel);

        for (const expected of ['WIDTH:', 'DEPTH:', 'i ←', 'o →', 'io ↔', 'r &']) {
            assert.ok(labels.includes(expected), `missing ${expected}: ${labels.join(', ')}`);
        }
        assert.ok(labels.every(label => !label.startsWith('module ')));
        const input = hints.find(hint => inlayHintLabel(hint) === 'i ←');
        assert.ok(input);
        assert.strictEqual(input.textEdits?.length, 2);
        assert.ok(Array.isArray(input.label));
        assert.ok(input.label[0].location);

        const namedLine = document.lineAt(8);
        const namedHints = await vscode.commands.executeCommand<vscode.InlayHint[]>(
            'vscode.executeInlayHintProvider',
            document.uri,
            namedLine.range,
        );
        const namedLabels = namedHints.map(inlayHintLabel);
        for (const expected of ['←', '→', '↔', '&']) {
            assert.ok(namedLabels.includes(expected), `missing ${expected}: ${namedLabels.join(', ')}`);
        }
        assert.ok(namedHints.every(hint => hint.textEdits === undefined));

        await replaceText(document, '.o(b), .io(c)', '.o(b),\n    .io(c)');
        try {
            const editedRange = new vscode.Range(8, 0, 9, document.lineAt(9).range.end.character);
            const editedHints = await waitFor(
                'inlay hints to follow an inserted newline',
                () => Promise.resolve(vscode.commands.executeCommand<vscode.InlayHint[]>(
                    'vscode.executeInlayHintProvider',
                    document.uri,
                    editedRange,
                )),
                value => value.some(hint => inlayHintLabel(hint) === '↔' && hint.position.line === 9),
            );
            const expectedPositions = new Map([
                ['←', positionOf(document, '.i(a)', 3)],
                ['→', positionOf(document, '.o(b)', 3)],
                ['↔', positionOf(document, '.io(c)', 4)],
                ['&', positionOf(document, '.r(d)', 3)],
            ]);
            for (const [label, position] of expectedPositions) {
                const hint = editedHints.find(candidate => inlayHintLabel(candidate) === label);
                assert.ok(hint, `missing edited ${label} hint`);
                assert.deepStrictEqual(hint.position, position, `${label} did not follow the edited port`);
            }
        } finally {
            await vscode.commands.executeCommand('workbench.action.files.revert');
        }
        await closeDocument(document);
    });

    test('does not diagnose an included compile unit as a duplicate definition', async () => {
        const included = await openFixture('src/sv/included_registers.v');
        await new Promise(resolve => setTimeout(resolve, 750));
        const diagnostics = vscode.languages.getDiagnostics(included.uri);
        assert.ok(diagnostics.every(
            diagnostic => diagnostic.code !== 'DuplicateDefinition',
        ), `included compile-unit diagnostics: ${JSON.stringify(diagnostics)}`);
        await closeDocument(included);
    });

    test('runs completion, definition, highlight, hover, symbol, lens, hint, and format providers', async () => {
        const document = await openFixture('src/sv/child.sv');
        const targetUse = positionOf(document, 'target <=', 2);

        const completion = await vscode.commands.executeCommand<vscode.CompletionList>(
            'vscode.executeCompletionItemProvider',
            document.uri,
            targetUse,
        );
        assert.ok(completion.items.some(item => item.label === 'target'));

        const definitions = await vscode.commands.executeCommand<Array<vscode.Location | vscode.LocationLink>>(
            'vscode.executeDefinitionProvider',
            document.uri,
            targetUse,
        );
        assert.ok(definitions.length > 0);
        const definitionRange = definitions[0] instanceof vscode.Location
            ? definitions[0].range
            : definitions[0].targetSelectionRange ?? definitions[0].targetRange;
        assert.ok(definitionRange);
        assert.strictEqual(definitionRange.start.line, 6);

        const highlights = await vscode.commands.executeCommand<vscode.DocumentHighlight[]>(
            'vscode.executeDocumentHighlights',
            document.uri,
            targetUse,
        );
        assert.ok(highlights.length >= 4, `highlights: ${JSON.stringify(highlights)}`);

        const hovers = await vscode.commands.executeCommand<vscode.Hover[]>(
            'vscode.executeHoverProvider',
            document.uri,
            targetUse,
        );
        assert.ok(hovers.length > 0);

        const symbols = await vscode.commands.executeCommand<Array<vscode.DocumentSymbol | vscode.SymbolInformation>>(
            'vscode.executeDocumentSymbolProvider',
            document.uri,
        );
        const names = flattenDocumentSymbols(symbols);
        for (const name of ['child', 'WIDTH', 'clk', 'out', 'target', 'value', 'worker']) {
            assert.ok(names.includes(name), `missing ${name} in ${names.join(', ')}`);
        }

        const codeLenses = await vscode.commands.executeCommand<vscode.CodeLens[]>(
            'vscode.executeCodeLensProvider',
            document.uri,
        );
        assert.ok(codeLenses.length >= 2);

        const inlayHints = await vscode.commands.executeCommand<vscode.InlayHint[]>(
            'vscode.executeInlayHintProvider',
            document.uri,
            new vscode.Range(new vscode.Position(0, 0), document.lineAt(document.lineCount - 1).range.end),
        );
        assert.ok(inlayHints.length >= 1);

        const formatting = await vscode.commands.executeCommand<vscode.TextEdit[]>(
            'vscode.executeFormatDocumentProvider',
            document.uri,
            { tabSize: 4, insertSpaces: true },
        );
        // VS Code normalizes an empty LSP TextEdit[] response to undefined.
        assert.ok(formatting === undefined || Array.isArray(formatting));

        await closeDocument(document);
    });

    test('resolves type definitions for variables, package classes, and typedef aliases', async () => {
        await writeFixture(
            'src/sv/type_defs.sv',
            [
                'package types_pkg;',
                '    typedef logic [7:0] base_t;',
                '    typedef base_t alias_t;',
                '    class item_class;',
                '    endclass',
                'endpackage',
                '',
            ].join('\n'),
        );
        await writeFixture(
            'src/sv/type_use.sv',
            [
                'module type_use;',
                '    import types_pkg::alias_t;',
                '    import types_pkg::*;',
                '    alias_t value;',
                '    types_pkg::item_class object;',
                '    initial begin',
                '        value = value;',
                '    end',
                'endmodule',
                '',
            ].join('\n'),
        );
        const definitions = await openFixture('src/sv/type_defs.sv');
        const uses = await openFixture('src/sv/type_use.sv');

        const variablePosition = positionOf(uses, 'value = value', 0, true);
        const variableTargets = await waitFor(
            'variable type definition',
            async () => vscode.commands.executeCommand<Array<vscode.Location | vscode.LocationLink>>(
                'vscode.executeTypeDefinitionProvider',
                uses.uri,
                variablePosition,
            ),
            targets => targets.length > 0,
        );
        assert.ok(variableTargets.some(target => {
            const uri = target instanceof vscode.Location ? target.uri : target.targetUri;
            return uri.fsPath.endsWith('type_defs.sv');
        }), `variable type targets: ${JSON.stringify(variableTargets)}`);

        const aliasTargets = await vscode.commands.executeCommand<Array<vscode.Location | vscode.LocationLink>>(
            'vscode.executeTypeDefinitionProvider',
            uses.uri,
            positionOf(uses, 'alias_t value'),
        );
        assert.ok(aliasTargets.some(target => {
            const uri = target instanceof vscode.Location ? target.uri : target.targetUri;
            return uri.fsPath.endsWith('type_defs.sv');
        }), `alias type targets: ${JSON.stringify(aliasTargets)}`);

        const classTargets = await vscode.commands.executeCommand<Array<vscode.Location | vscode.LocationLink>>(
            'vscode.executeTypeDefinitionProvider',
            uses.uri,
            positionOf(uses, 'types_pkg::item_class'),
        );
        assert.ok(classTargets.some(target => {
            const uri = target instanceof vscode.Location ? target.uri : target.targetUri;
            return uri.fsPath.endsWith('type_defs.sv');
        }), `class type targets: ${JSON.stringify(classTargets)}`);

        const packageTargets = await vscode.commands.executeCommand<Array<vscode.Location | vscode.LocationLink>>(
            'vscode.executeTypeDefinitionProvider',
            uses.uri,
            positionOf(uses, 'import ', 'import '.length),
        );
        assert.ok(packageTargets.some(target => {
            const uri = target instanceof vscode.Location ? target.uri : target.targetUri;
            return uri.fsPath.endsWith('type_defs.sv');
        }), `package type targets: ${JSON.stringify(packageTargets)}`);

        await closeDocument(uses);
        await closeDocument(definitions);
    });

    test('formats preprocessor source through VS Code and converges', async () => {
        const source = [
            '`define ENABLED',
            '`define PICK(a,b) ((a) ? (a) : (b))',
            '`include "formatter_defs.svh"',
            'module formatter_top(input logic a,b,output logic y);',
            '`ifdef ENABLED',
            'assign y=`PICK(a,b);',
            '`else',
            'inactive text that is intentionally not valid SystemVerilog',
            '`endif',
            'endmodule',
            '',
        ].join('\n');
        await writeFixture('src/sv/formatter_defs.svh', '`define FROM_INCLUDE 1\n');
        await writeFixture('src/sv/formatter.sv', source);
        const document = await openFixture('src/sv/formatter.sv');

        const edits = await vscode.commands.executeCommand<vscode.TextEdit[]>(
            'vscode.executeFormatDocumentProvider',
            document.uri,
            { tabSize: 2, insertSpaces: true },
        );
        assert.ok(Array.isArray(edits) && edits.length > 0, `formatter edits: ${JSON.stringify(edits)}`);
        const workspaceEdit = new vscode.WorkspaceEdit();
        workspaceEdit.set(document.uri, edits);
        assert.ok(await vscode.workspace.applyEdit(workspaceEdit), 'failed to apply formatter edit');

        const formatted = document.getText();
        assert.ok(formatted.startsWith([
            '`define ENABLED',
            '`define PICK(a, b) ((a) ? (a) : (b))',
            '`include "formatter_defs.svh"',
            '',
        ].join('\n')));
        assert.ok(formatted.includes('assign y = `PICK(a,b);'));
        assert.ok(formatted.includes([
            '`else',
            'inactive text that is intentionally not valid SystemVerilog',
            '`endif',
        ].join('\n')));

        const second = await vscode.commands.executeCommand<vscode.TextEdit[]>(
            'vscode.executeFormatDocumentProvider',
            document.uri,
            { tabSize: 2, insertSpaces: true },
        );
        assert.ok(second === undefined || second.length === 0, `formatter did not converge: ${JSON.stringify(second)}`);
        await closeDocument(document);
    });

    test('uses ScopeTree for nearest-scope completion and definition', async () => {
        const document = await openFixture('src/sv/scopes.sv');
        const use = positionOf(document, 'value =', 2);
        const completion = await vscode.commands.executeCommand<vscode.CompletionList>(
            'vscode.executeCompletionItemProvider',
            document.uri,
            use,
        );
        assert.ok(completion.items.some(item => item.label === 'value'));

        const definitions = await vscode.commands.executeCommand<Array<vscode.Location | vscode.LocationLink>>(
            'vscode.executeDefinitionProvider',
            document.uri,
            use,
        );
        assert.ok(definitions.length > 0);
        const range = definitions[0] instanceof vscode.Location
            ? definitions[0].range
            : definitions[0].targetSelectionRange ?? definitions[0].targetRange;
        assert.ok(range);
        assert.strictEqual(range.start.line, 4, 'definition did not resolve to the nested declaration');
        await closeDocument(document);
    });

    test('runs references, prepare rename, rename, and workspace symbol providers', async () => {
        const api = await activateExtension();
        const document = await openFixture('src/sv/child.sv');
        const target = positionOf(document, 'target <=', 2);
        const references = await vscode.commands.executeCommand<vscode.Location[]>(
            'vscode.executeReferenceProvider',
            document.uri,
            target,
        );
        assert.ok(references.length >= 4, `references: ${JSON.stringify(references)}`);

        const prepared = await api.client.sendRequest<{ placeholder: string } | null>(
            'textDocument/prepareRename',
            {
                textDocument: { uri: document.uri.toString() },
                position: { line: target.line, character: target.character },
            },
        );
        assert.strictEqual(prepared?.placeholder, 'target');
        const rename = await vscode.commands.executeCommand<vscode.WorkspaceEdit>(
            'vscode.executeDocumentRenameProvider',
            document.uri,
            target,
            'renamed_target',
        );
        const edits = rename.entries().find(([uri]) => uri.toString() === document.uri.toString())?.[1] ?? [];
        assert.ok(edits.length >= 4, `rename edits: ${JSON.stringify(rename.entries())}`);

        const symbols = await vscode.commands.executeCommand<vscode.SymbolInformation[]>(
            'vscode.executeWorkspaceSymbolProvider',
            'target',
        );
        assert.ok(symbols.some(symbol => symbol.name === 'target' && symbol.location.uri.fsPath.endsWith('child.sv')));
        await closeDocument(document);
    });

    test('resolves module, include, and macro definitions across files', async () => {
        const api = await activateExtension();
        const top = await openFixture('src/sv/top.sv');
        const moduleDefinitions = await vscode.commands.executeCommand<Array<vscode.Location | vscode.LocationLink>>(
            'vscode.executeDefinitionProvider',
            top.uri,
            positionOf(top, 'child #', 2),
        );
        assert.ok(moduleDefinitions.length > 0);
        const moduleUri = moduleDefinitions[0] instanceof vscode.Location
            ? moduleDefinitions[0].uri
            : moduleDefinitions[0].targetUri;
        assert.ok(moduleUri.fsPath.endsWith('child.sv'));
        await closeDocument(top);

        const include = await openFixture('src/sv/include_top.sv');
        const includeDefinitions = await vscode.commands.executeCommand<Array<vscode.Location | vscode.LocationLink>>(
            'vscode.executeDefinitionProvider',
            include.uri,
            positionOf(include, 'defs.svh', 2),
        );
        assert.ok(includeDefinitions.length > 0);
        const includeUri = includeDefinitions[0] instanceof vscode.Location
            ? includeDefinitions[0].uri
            : includeDefinitions[0].targetUri;
        assert.ok(includeUri.fsPath.endsWith('defs.svh'));

        const macroDefinitions = await vscode.commands.executeCommand<Array<vscode.Location | vscode.LocationLink>>(
            'vscode.executeDefinitionProvider',
            include.uri,
            positionOf(include, 'MAGIC_VALUE', 2),
        );
        assert.ok(
            macroDefinitions.length > 0,
            `macro definition provider returned no locations for \`MAGIC_VALUE; index: ${JSON.stringify(
                (await api.client.sendRequest<unknown[]>('hdlparams/request')).filter(entry =>
                    JSON.stringify(entry).includes('defs.svh'),
                ),
            )}`,
        );
        const macroUri = macroDefinitions[0] instanceof vscode.Location
            ? macroDefinitions[0].uri
            : macroDefinitions[0].targetUri;
        assert.ok(macroUri.fsPath.endsWith('defs.svh'));
        await closeDocument(include);
    });

    test('reports incoming and outgoing module instance call hierarchy', async () => {
        const child = await openFixture('src/sv/child.sv');
        const prepared = await vscode.commands.executeCommand<vscode.CallHierarchyItem[]>(
            'vscode.prepareCallHierarchy',
            child.uri,
            positionOf(child, 'module child', 'module '.length),
        );
        const childItem = prepared.find(item => item.name === 'child');
        assert.ok(childItem, `call hierarchy roots: ${JSON.stringify(prepared)}`);
        assert.strictEqual(childItem.kind, vscode.SymbolKind.Module);

        const top = await openFixture('src/sv/top.sv');
        const preparedFromInstance = await vscode.commands.executeCommand<vscode.CallHierarchyItem[]>(
            'vscode.prepareCallHierarchy',
            top.uri,
            positionOf(top, 'child #', 2),
        );
        assert.ok(preparedFromInstance.some(item =>
            item.name === 'child' && item.uri.fsPath.endsWith('child.sv'),
        ));
        await closeDocument(top);

        const incoming = await vscode.commands.executeCommand<vscode.CallHierarchyIncomingCall[]>(
            'vscode.provideIncomingCalls',
            childItem,
        );
        const topCall = incoming.find(call => call.from.name === 'top');
        assert.ok(topCall, `incoming calls: ${JSON.stringify(incoming)}`);
        assert.ok(topCall.from.uri.fsPath.endsWith('top.sv'));
        assert.ok(topCall.fromRanges.some(range => range.start.line === 4));

        const outgoing = await vscode.commands.executeCommand<vscode.CallHierarchyOutgoingCall[]>(
            'vscode.provideOutgoingCalls',
            childItem,
        );
        const leafCall = outgoing.find(call => call.to.name === 'leaf');
        assert.ok(leafCall, `outgoing calls: ${JSON.stringify(outgoing)}`);
        assert.ok(leafCall.to.uri.fsPath.endsWith('leaf.sv'));
        assert.ok(leafCall.fromRanges.some(range => range.start.line === 17));
        await closeDocument(child);
    });

    test('provides system task and preprocessor completion contexts', async () => {
        const child = await openFixture('src/sv/child.sv');
        const systemTasks = await vscode.commands.executeCommand<vscode.CompletionList>(
            'vscode.executeCompletionItemProvider',
            child.uri,
            positionOf(child, '$display', 1),
            '$',
        );
        assert.ok(
            systemTasks.items.some(item => completionLabel(item) === 'display'),
            `system task completions: ${systemTasks.items.map(completionLabel).join(', ')}`,
        );
        const display = systemTasks.items.find(item => completionLabel(item) === 'display');
        assert.ok(display);
        assert.strictEqual(completionInsertText(display), 'display($1);');
        await closeDocument(child);

        const include = await openFixture('src/sv/include_top.sv');
        const directives = await vscode.commands.executeCommand<vscode.CompletionList>(
            'vscode.executeCompletionItemProvider',
            include.uri,
            positionOf(include, '`include', 1),
            '`',
        );
        assert.ok(
            directives.items.some(item => completionLabel(item).includes('include')),
            `directive completions: ${directives.items.map(completionLabel).join(', ')}`,
        );
        const timescale = directives.items.find(item => completionLabel(item) === 'timescale');
        assert.ok(timescale);
        assert.strictEqual(
            completionInsertText(timescale),
            'timescale ${1:1ns}/${2:1ps}',
        );
        await closeDocument(include);
    });

    test('keeps completion trigger characters exactly once after accepting snippets', async () => {
        await writeFixture(
            'src/sv/completion_triggers.v',
            [
                '',
                'module completion_triggers;',
                '    initial begin',
                '        ',
                '    end',
                'endmodule',
                '',
            ].join('\n'),
        );
        const document = await openFixture('src/sv/completion_triggers.v');
        const editor = vscode.window.activeTextEditor;
        assert.ok(editor);

        editor.selection = new vscode.Selection(0, 0, 0, 0);
        await vscode.commands.executeCommand('workbench.action.focusActiveEditorGroup');
        await vscode.commands.executeCommand('type', { text: '`' });
        await new Promise(resolve => setTimeout(resolve, 250));
        await vscode.commands.executeCommand('type', { text: 'tim' });
        await new Promise(resolve => setTimeout(resolve, 500));
        await vscode.commands.executeCommand('acceptSelectedSuggestion');
        await waitFor(
            'timescale directive completion without a duplicate backtick',
            () => document.lineAt(0).text.trim(),
            line => line === '`timescale 1ns/1ps',
        );

        const systemTaskPosition = new vscode.Position(3, 8);
        editor.selection = new vscode.Selection(systemTaskPosition, systemTaskPosition);
        await vscode.commands.executeCommand('type', { text: '$' });
        await new Promise(resolve => setTimeout(resolve, 250));
        await vscode.commands.executeCommand('type', { text: 'dis' });
        await new Promise(resolve => setTimeout(resolve, 500));
        await vscode.commands.executeCommand('acceptSelectedSuggestion');
        await waitFor(
            'system task completion without a duplicate dollar',
            () => document.lineAt(3).text.trim(),
            line => line === '$display();',
        );

        await vscode.commands.executeCommand('workbench.action.files.revert');
        await closeDocument(document);
    });

    test('publishes parse, semantic, and inactive-branch diagnostics', async () => {
        const invalid = await openFixture('src/sv/invalid.sv');
        const semantic = await waitForDiagnostics(
            invalid.uri,
            diagnostics => diagnostics.some(diagnostic => diagnostic.source === 'Digital-IDE'),
        );
        assert.ok(semantic.every(diagnostic => diagnostic.source === 'Digital-IDE'));
        assert.ok(semantic.some(diagnostic => diagnostic.severity === vscode.DiagnosticSeverity.Error));
        await closeDocument(invalid);

        const inactive = await openFixture('src/sv/inactive.sv');
        const inactiveDiagnostics = await waitForDiagnostics(
            inactive.uri,
            diagnostics => diagnostics.some(diagnostic => diagnostic.code === 'inactive-preprocessor-branch'),
        );
        assert.ok(inactiveDiagnostics.some(diagnostic => diagnostic.tags?.includes(vscode.DiagnosticTag.Unnecessary)));
        await closeDocument(inactive);
    });

    test('disables any Digital-IDE error or warning through a persistent Quick Fix', async () => {
        const missingUri = await writeFixture(
            'src/sv/quick_fix_missing_timescale.sv',
            'module quick_fix_missing_timescale; endmodule\n',
        );
        await writeFixture(
            'src/sv/quick_fix_with_timescale.sv',
            '`timescale 1ns/1ps\nmodule quick_fix_with_timescale; endmodule\n',
        );
        await writeFixture(
            'src/sv/quick_fix_other_error.sv',
            [
                'module quick_fix_other_error(',
                '  input logic broken',
                'endmodule',
                '',
            ].join('\n'),
        );
        const timescaleDocument = await openFixture('src/sv/quick_fix_with_timescale.sv');
        await closeDocument(timescaleDocument);
        const configuration = vscode.workspace.getConfiguration(
            'digital-ide.function.lsp.diagnostics',
            missingUri,
        );
        const previous = configuration
            .inspect<Record<string, string>>('overrides')
            ?.workspaceFolderValue;
        let document: vscode.TextDocument | undefined;

        try {
            const initialOverrides: Record<string, string> = {};
            initialOverrides['ExistingDiagnostic'] = 'off';
            await configuration.update(
                'overrides',
                initialOverrides,
                vscode.ConfigurationTarget.WorkspaceFolder,
            );
            document = await openFixture('src/sv/quick_fix_missing_timescale.sv');
            const diagnostics = await waitForDiagnostics(
                document.uri,
                current => current.some(diagnostic => diagnostic.code === 'MissingTimeScale'),
                'MissingTimeScale diagnostic before applying its Quick Fix',
            );
            const diagnostic = diagnostics.find(
                candidate => candidate.code === 'MissingTimeScale',
            );
            assert.ok(diagnostic);
            assert.ok(
                diagnostic.severity === vscode.DiagnosticSeverity.Error
                    || diagnostic.severity === vscode.DiagnosticSeverity.Warning,
            );

            const actions = await vscode.commands.executeCommand<Array<
                vscode.CodeAction | vscode.Command
            >>(
                'vscode.executeCodeActionProvider',
                document.uri,
                diagnostic.range,
                vscode.CodeActionKind.QuickFix.value,
            ) ?? [];
            const disableAction = actions.find(
                (action): action is vscode.CodeAction => action instanceof vscode.CodeAction
                    && action.title === 'Disable this error',
            );
            assert.ok(disableAction, `Quick Fixes: ${actions.map(action => action.title).join(', ')}`);
            const command = disableAction.command;
            assert.ok(command);
            assert.strictEqual(command.arguments?.[1], 'MissingTimeScale');
            await vscode.commands.executeCommand(command.command, ...(command.arguments ?? []));

            const overrides = await waitFor(
                'workspace diagnostic overrides to be persisted',
                () => vscode.workspace.getConfiguration(
                    'digital-ide.function.lsp.diagnostics',
                    missingUri,
                ).get<Record<string, string>>('overrides', {}),
                current => current.ExistingDiagnostic === 'off'
                    && current.MissingTimeScale === 'off',
            );
            const expectedOverrides: Record<string, string> = {};
            expectedOverrides['ExistingDiagnostic'] = 'off';
            expectedOverrides['MissingTimeScale'] = 'off';
            assert.deepStrictEqual(overrides, expectedOverrides);

            const folder = vscode.workspace.getWorkspaceFolder(document.uri);
            assert.ok(folder);
            await waitFor(
                'all MissingTimeScale diagnostics in the workspace folder to disappear',
                () => vscode.languages.getDiagnostics(),
                entries => entries
                    .filter(([uri]) => vscode.workspace.getWorkspaceFolder(uri)?.uri.toString()
                        === folder.uri.toString())
                    .every(([, current]) => current.every(
                        candidate => candidate.code !== 'MissingTimeScale',
                    )),
            );

            await closeDocument(document);
            document = undefined;
            document = await openFixture('src/sv/quick_fix_missing_timescale.sv');
            await new Promise(resolve => setTimeout(resolve, 750));
            assert.ok(vscode.languages.getDiagnostics(document.uri).every(
                candidate => candidate.code !== 'MissingTimeScale',
            ));

            await closeDocument(document);
            document = undefined;
            document = await openFixture('src/sv/quick_fix_other_error.sv');
            const otherDiagnostics = await waitForDiagnostics(
                document.uri,
                current => current.some(candidate => candidate.source === 'Digital-IDE'
                    && candidate.code !== undefined
                    && candidate.code !== 'MissingTimeScale'
                    && (candidate.severity === vscode.DiagnosticSeverity.Error
                        || candidate.severity === vscode.DiagnosticSeverity.Warning)),
                'a second Digital-IDE error or warning code',
            );
            const otherDiagnostic = otherDiagnostics.find(
                candidate => candidate.source === 'Digital-IDE'
                    && candidate.code !== undefined
                    && candidate.code !== 'MissingTimeScale'
                    && (candidate.severity === vscode.DiagnosticSeverity.Error
                        || candidate.severity === vscode.DiagnosticSeverity.Warning),
            );
            assert.ok(otherDiagnostic);
            const otherCode = String(otherDiagnostic.code);
            const otherActions = await vscode.commands.executeCommand<Array<
                vscode.CodeAction | vscode.Command
            >>(
                'vscode.executeCodeActionProvider',
                document.uri,
                otherDiagnostic.range,
                vscode.CodeActionKind.QuickFix.value,
            ) ?? [];
            const otherDisableAction = otherActions.find(
                (action): action is vscode.CodeAction => action instanceof vscode.CodeAction
                    && action.title === 'Disable this error'
                    && action.command?.arguments?.[1] === otherCode,
            );
            assert.ok(
                otherDisableAction,
                `Quick Fixes for ${otherCode}: ${otherActions.map(action => action.title).join(', ')}`,
            );
            const otherCommand = otherDisableAction.command;
            assert.ok(otherCommand);
            await vscode.commands.executeCommand(
                otherCommand.command,
                ...(otherCommand.arguments ?? []),
            );

            expectedOverrides[otherCode] = 'off';
            const finalOverrides = await waitFor(
                `workspace diagnostic override for ${otherCode}`,
                () => vscode.workspace.getConfiguration(
                    'digital-ide.function.lsp.diagnostics',
                    missingUri,
                ).get<Record<string, string>>('overrides', {}),
                current => current[otherCode] === 'off',
            );
            assert.deepStrictEqual(finalOverrides, expectedOverrides);
            await waitForDiagnostics(
                document.uri,
                current => current.every(candidate => String(candidate.code) !== otherCode),
                `${otherCode} diagnostics to disappear immediately`,
            );

            const settingsBytes = await vscode.workspace.fs.readFile(
                vscode.Uri.joinPath(folder.uri, '.vscode', 'settings.json'),
            );
            const settings = JSON.parse(Buffer.from(settingsBytes).toString('utf8')) as Record<
                string,
                unknown
            >;
            assert.deepStrictEqual(
                settings['digital-ide.function.lsp.diagnostics.overrides'],
                expectedOverrides,
            );
        } finally {
            if (document) {
                await closeDocument(document);
            }
            await configuration.update(
                'overrides',
                previous,
                vscode.ConfigurationTarget.WorkspaceFolder,
            );
        }
    });

    test('updates diagnostics through unsaved edits, save, close, and reopen', async () => {
        const document = await openFixture('src/sv/invalid.sv');
        await waitForDiagnostics(
            document.uri,
            diagnostics => diagnostics.some(diagnostic => diagnostic.source === 'Digital-IDE'),
        );

        await replaceText(document, 'wire duplicate;', 'wire duplicate_wire;');
        await waitForDiagnostics(
            document.uri,
            diagnostics => diagnostics.every(diagnostic => ![
                'DuplicateDefinition',
                'Redefinition',
                'RedefinitionDifferentType',
            ].includes(String(diagnostic.code))),
            'semantic diagnostics to clear after didChange',
        );
        assert.ok(await document.save());
        await closeDocument(document);

        const reopened = await openFixture('src/sv/invalid.sv');
        await waitForDiagnostics(
            reopened.uri,
            diagnostics => diagnostics.every(diagnostic => ![
                'DuplicateDefinition',
                'Redefinition',
                'RedefinitionDifferentType',
            ].includes(String(diagnostic.code))),
            'saved diagnostics to remain clear after reopen',
        );
        await closeDocument(reopened);
    });

    test('keeps duplicate diagnostics for independent compilation roots', async () => {
        const firstUri = await writeFixture(
            'src/sv/independent_duplicate_a.v',
            'module independent_duplicate; endmodule\n',
        );
        const secondUri = await writeFixture(
            'src/sv/independent_duplicate_b.v',
            'module independent_duplicate; endmodule\n',
        );
        const first = await openFixture('src/sv/independent_duplicate_a.v');
        const second = await openFixture('src/sv/independent_duplicate_b.v');
        await waitFor(
            'a duplicate definition from independent compilation roots',
            () => [
                ...vscode.languages.getDiagnostics(firstUri),
                ...vscode.languages.getDiagnostics(secondUri),
            ],
            diagnostics => diagnostics.some(
                diagnostic => diagnostic.code === 'DuplicateDefinition',
            ),
        );
        await closeDocument(second);
        await closeDocument(first);
    });
});
