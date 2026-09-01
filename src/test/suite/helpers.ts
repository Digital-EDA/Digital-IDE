import * as assert from 'assert';
import * as path from 'path';
import * as vscode from 'vscode';
import type { DigitalIdeExtensionApi } from '../../extension';
import type { DigitalServerExtensionApi } from '../../server/server';

const extensionId = 'sterben.fpga-support';
const defaultTimeout = 20_000;

export function workspacePath(): string {
    const value = process.env.DIGITAL_TEST_WORKSPACE;
    assert.ok(value, 'DIGITAL_TEST_WORKSPACE is not set');
    return value;
}

export function workspaceUri(relativePath: string): vscode.Uri {
    return vscode.Uri.file(path.join(workspacePath(), relativePath));
}

export async function activateExtension(): Promise<DigitalServerExtensionApi> {
    const extension = vscode.extensions.getExtension<DigitalIdeExtensionApi>(extensionId);
    assert.ok(extension, `extension ${extensionId} is not installed in the test host`);
    const activation = await extension.activate();
    const api = await activation.ready;
    assert.ok(extension.isActive, 'extension did not activate');
    return api;
}

export async function writeFixture(relativePath: string, contents: string): Promise<vscode.Uri> {
    const uri = workspaceUri(relativePath);
    await vscode.workspace.fs.createDirectory(vscode.Uri.file(path.dirname(uri.fsPath)));
    await vscode.workspace.fs.writeFile(uri, Buffer.from(contents));
    return uri;
}

export async function openFixture(relativePath: string): Promise<vscode.TextDocument> {
    const document = await vscode.workspace.openTextDocument(workspaceUri(relativePath));
    await vscode.window.showTextDocument(document, { preview: false });
    return document;
}

export function positionOf(
    document: vscode.TextDocument,
    needle: string,
    offset = 0,
    fromEnd = false,
): vscode.Position {
    const text = document.getText();
    const index = fromEnd ? text.lastIndexOf(needle) : text.indexOf(needle);
    assert.notStrictEqual(index, -1, `missing fixture text: ${needle}`);
    return document.positionAt(index + offset);
}

export async function waitFor<T>(
    description: string,
    read: () => T | Promise<T>,
    predicate: (value: T) => boolean,
    timeout = defaultTimeout,
): Promise<T> {
    const deadline = Date.now() + timeout;
    let value = await read();
    while (!predicate(value)) {
        if (Date.now() >= deadline) {
            assert.fail(`timed out waiting for ${description}; last value: ${JSON.stringify(value)}`);
        }
        await new Promise(resolve => setTimeout(resolve, 100));
        value = await read();
    }
    return value;
}

export async function waitForDiagnostics(
    uri: vscode.Uri,
    predicate: (diagnostics: readonly vscode.Diagnostic[]) => boolean,
    description = `diagnostics for ${uri.fsPath}`,
    timeout = defaultTimeout,
): Promise<readonly vscode.Diagnostic[]> {
    const current = vscode.languages.getDiagnostics(uri);
    if (predicate(current)) {
        return current;
    }

    return new Promise((resolve, reject) => {
        const timer = setTimeout(() => {
            subscription.dispose();
            reject(new Error(`timed out waiting for ${description}`));
        }, timeout);
        const subscription = vscode.languages.onDidChangeDiagnostics(event => {
            if (!event.uris.some(changed => changed.toString() === uri.toString())) {
                return;
            }
            const diagnostics = vscode.languages.getDiagnostics(uri);
            if (predicate(diagnostics)) {
                clearTimeout(timer);
                subscription.dispose();
                resolve(diagnostics);
            }
        });
    });
}

export async function replaceText(
    document: vscode.TextDocument,
    oldText: string,
    newText: string,
): Promise<void> {
    const start = positionOf(document, oldText);
    const edit = new vscode.WorkspaceEdit();
    edit.replace(document.uri, new vscode.Range(start, start.translate(0, oldText.length)), newText);
    assert.ok(await vscode.workspace.applyEdit(edit), `failed to replace ${oldText}`);
}

export async function closeDocument(document: vscode.TextDocument): Promise<void> {
    await vscode.window.showTextDocument(document, { preview: false });
    await vscode.commands.executeCommand('workbench.action.closeActiveEditor');
}

export function flattenDocumentSymbols(
    symbols: readonly (vscode.DocumentSymbol | vscode.SymbolInformation)[],
): string[] {
    const names: string[] = [];
    const visit = (symbol: vscode.DocumentSymbol | vscode.SymbolInformation): void => {
        names.push(symbol.name);
        const children = (symbol as vscode.DocumentSymbol).children;
        if (Array.isArray(children)) {
            children.forEach(visit);
        }
    };
    symbols.forEach(visit);
    return names;
}

export function completionLabel(item: vscode.CompletionItem): string {
    return typeof item.label === 'string' ? item.label : item.label.label;
}
