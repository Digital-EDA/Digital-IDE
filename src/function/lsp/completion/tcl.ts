import * as vscode from 'vscode';

import { tclKeyword } from '../util/keyword';
import { MainOutput } from '../../../global';


class TCLCompletionProvider implements vscode.CompletionItemProvider {
    keywordsCompletionItems: vscode.CompletionItem[] | undefined;
    constructor() {
        this.keywordsCompletionItems = this.provideKeywords();
    }
    public provideCompletionItems(document: vscode.TextDocument, position: vscode.Position, token: vscode.CancellationToken, context: vscode.CompletionContext): vscode.ProviderResult<vscode.CompletionItem[] | vscode.CompletionList<vscode.CompletionItem>> {        
        try {
            const items = this.provideKeywords();
            return items;
        } catch (err) {
            console.log(err);
        }
    }

    private provideKeywords(): vscode.CompletionItem[] {
        if (this.keywordsCompletionItems === undefined) {
            const keywords: vscode.CompletionItem[] = [];
            for (const tcl of tclKeyword.keys()) {
                const item = new vscode.CompletionItem(tcl);
                item.kind = vscode.CompletionItemKind.Keyword;
                keywords.push(item);
            }
            this.keywordsCompletionItems = keywords;
        }
        
        return this.keywordsCompletionItems;
    }
}

const tclCompletionProvider = new TCLCompletionProvider();

export {
    tclCompletionProvider
};