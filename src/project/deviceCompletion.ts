import * as fs from 'fs';
import * as path from 'path';
import * as vscode from 'vscode';
import { DeviceCatalog, deviceValueContext, suggestDevices } from './deviceCatalog';

export function registerDeviceCompletion(context: vscode.ExtensionContext): void {
    context.subscriptions.push(vscode.languages.registerCompletionItemProvider(
        [
            { language: 'json', pattern: '**/.vscode/property.json' },
            { language: 'jsonc', pattern: '**/.vscode/property.json' },
        ],
        createDeviceCompletionProvider(context.extensionPath),
        '"', '-',
    ));
}

export function createDeviceCompletionProvider(extensionPath: string): vscode.CompletionItemProvider {
    const catalogs = new Map<string, DeviceCatalog>();
    return {
        provideCompletionItems(document, position, token) {
            const location = deviceValueContext(document.getText(), document.offsetAt(position));
            if (!location || token.isCancellationRequested) {return undefined;}
            let catalog = catalogs.get(location.vendor);
            if (!catalog) {
                catalog = JSON.parse(fs.readFileSync(path.join(extensionPath,
                    'resources', 'property', 'devices', `${location.vendor}.json`), 'utf8')) as DeviceCatalog;
                catalogs.set(location.vendor, catalog);
            }
            const range = new vscode.Range(document.positionAt(location.start), document.positionAt(location.end));
            const stages = { family: '系列', device: '芯片', package: '封装', part: '完整型号' };
            const items = suggestDevices(catalog, location.prefix).map((suggestion, index) => {
                const item = new vscode.CompletionItem(suggestion.label, vscode.CompletionItemKind.Value);
                item.detail = `${stages[suggestion.stage]} · ${suggestion.detail}`;
                item.documentation = `${catalog!.source}\n仅提供补全建议，也可以自由填写其他型号。`;
                item.range = range;
                item.filterText = `"${suggestion.value}`;
                item.sortText = String(index).padStart(5, '0');
                item.insertText = new vscode.SnippetString().appendText(`"${suggestion.value}`)
                    .appendTabstop(0).appendText('"');
                if (suggestion.stage !== 'part') {
                    item.command = { command: 'editor.action.triggerSuggest', title: '继续选择器件' };
                }
                return item;
            });
            return new vscode.CompletionList(items, true);
        },
    };
}
