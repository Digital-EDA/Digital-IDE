import * as vscode from 'vscode';
import { HdlLangID } from '../../../global/enum';

interface BaseLinter {
    diagnostic: vscode.DiagnosticCollection;
    lint(document: vscode.TextDocument): Promise<void>;
    remove(uri: vscode.Uri): Promise<void>;
    initialise(langID: HdlLangID): Promise<boolean>;
}

interface BaseManager {
    initialise(): Promise<void>;
    updateLinter(): Promise<boolean>;
}


export {
    BaseLinter,
    BaseManager
};
