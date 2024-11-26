import * as vscode from 'vscode';
import { LspOutput, ReportType } from '../../../global';
import { HdlLangID } from '../../../global/enum';
import { BaseLinter, BaseManager } from './base';
import { defaultVhdlLinter } from './default';
import { modelsimLinter } from './modelsim';
import { vivadoLinter } from './vivado';
import { hdlFile, hdlPath } from '../../../hdlFs';

class VhdlLinterManager implements BaseManager {
    currentLinter: BaseLinter | undefined;
    activateLinterName: string;
    statusBarItem: vscode.StatusBarItem;
    initialized: boolean;

    constructor() {
        this.activateLinterName = 'default';
        this.initialized = false;

        // make a status bar for rendering
        this.statusBarItem = vscode.window.createStatusBarItem(vscode.StatusBarAlignment.Right);
        this.statusBarItem.command = 'digital-ide.lsp.vhdl.linter.pick';

        // when changing file, hide if langID is not vhdl
        vscode.window.onDidChangeActiveTextEditor(editor => {
            if (!editor) {
                return;
            }
            const currentFileName = hdlPath.toSlash(editor.document.fileName);
                        
            if (hdlFile.isVhdlFile(currentFileName)) {
                this.statusBarItem.show();
            } else {
                this.statusBarItem.hide();
            }
        });

        // update when user's config is changed
        vscode.workspace.onDidChangeConfiguration(() => {
            this.updateLinter();
        });
    }

    async initialise(): Promise<void> {
        const success = await this.updateLinter();
        
        if (!success) {
            return;
        }

        this.initialized = true;

        for (const doc of vscode.workspace.textDocuments) {
            const fileName = hdlPath.toSlash(doc.fileName);
            if (hdlFile.isVhdlFile(fileName)) {
                await this.lint(doc);
            }
        }
        LspOutput.report('<vhdl lsp manager> finish initialization of vhdl linter. Linter name: ' + this.activateLinterName, {
            level: ReportType.Launch
        });
              
        // hide it if current window is not vhdl
        const editor = vscode.window.activeTextEditor;
        if (editor && hdlFile.isVhdlFile(editor.document.fileName)) {
            this.statusBarItem.show();
        } else {
            this.statusBarItem.hide();
        }
    }

    async lint(document: vscode.TextDocument) {
        this.currentLinter?.remove(document.uri);
        await this.currentLinter?.lint(document);
    }

    async remove(uri: vscode.Uri): Promise<void> {
        this.currentLinter?.remove(uri);
    }

    public getUserDiagnostorSelection() {
        const vhdlLspConfig = vscode.workspace.getConfiguration('digital-ide.function.lsp.linter.vhdl');
        const diagnostor = vhdlLspConfig.get('diagnostor', 'xxx');
        return diagnostor;
    }

    public async updateLinter(): Promise<boolean> {        
        const diagnostorName = this.getUserDiagnostorSelection();
        
        const lastDiagnostorName = this.activateLinterName;
        const lastDiagnostor = this.currentLinter;
        
        if (this.initialized && diagnostorName === lastDiagnostorName) {
            // no need for update
            return true;
        }
        LspOutput.report(`<vhdl lsp manager> detect linter setting changes, switch from ${lastDiagnostorName} to ${diagnostorName}.`, {
            level: ReportType.Launch
        });

        let launch = false;
        switch (diagnostorName) {
            case 'vivado':    launch = await this.activateVivado(); break;
            case 'modelsim':  launch = await this.activateModelsim(); break;
            case 'default':   launch = await this.activateDefault(); break;
            default:          launch = await this.activateDefault(); break;
        }

        for (const doc of vscode.workspace.textDocuments) {
            const fileName = hdlPath.toSlash(doc.fileName);
            if (hdlFile.isVhdlFile(fileName)) {
                lastDiagnostor?.remove(doc.uri);
                await this.lint(doc);
            }
        }

        return launch;
    }

    public async activateVivado(): Promise<boolean> {
        const selectedLinter = vivadoLinter;
        let launch = true;

        launch = await selectedLinter.initialise(HdlLangID.Vhdl);            
        if (launch) {
            this.statusBarItem.text = '$(getting-started-beginner) Linter(vivado)';

            LspOutput.report('<vhdl lsp manager> vivado linter has been activated');
        } else {
            this.statusBarItem.backgroundColor = new vscode.ThemeColor('statusBarItem.warningBackground');
            this.statusBarItem.tooltip = 'Fail to launch vivado linter';
            this.statusBarItem.text = '$(extensions-warning-message) Linter(vivado)';

            LspOutput.report('<vhdl lsp manager> Fail to launch vivado linter', {
                level: ReportType.Error
            });
        }

        this.currentLinter = selectedLinter;
        this.activateLinterName = 'vivado';
        this.statusBarItem.show();
        
        return launch;
    }

    public async activateModelsim(): Promise<boolean> {
        const selectedLinter = modelsimLinter;
        let launch = true;

        launch = await selectedLinter.initialise(HdlLangID.Vhdl);
        if (launch) {
            this.statusBarItem.text = '$(getting-started-beginner) Linter(modelsim)';

            LspOutput.report('<vhdl lsp manager> modelsim linter has been activated');
        } else {
            this.statusBarItem.backgroundColor = new vscode.ThemeColor('statusBarItem.warningBackground');
            this.statusBarItem.tooltip = 'Fail to launch modelsim linter';
            this.statusBarItem.text = '$(extensions-warning-message) Linter(modelsim)';

            LspOutput.report('<vhdl lsp manager> Fail to launch modelsim linter', {
                level: ReportType.Error
            });
        }

        this.currentLinter = selectedLinter;
        this.activateLinterName = 'modelsim';
        this.statusBarItem.show();

        return launch;
    }

    public async activateDefault(): Promise<boolean> {
        const selectedLinter = defaultVhdlLinter;
        let launch = true;

        if (launch) {
            this.statusBarItem.text = '$(getting-started-beginner) Linter(default)';
            
            LspOutput.report('<vhdl lsp manager> default build-in linter has been activated');
        } else {
            this.statusBarItem.backgroundColor = undefined;
            this.statusBarItem.tooltip = 'Fail to launch default linter';
            this.statusBarItem.text = '$(extensions-warning-message) Linter(default)';

            LspOutput.report('<vhdl lsp manager> Fail to launch default linter', {
                level: ReportType.Error
            });
        }

        this.currentLinter = selectedLinter;
        this.activateLinterName = 'default';
        this.statusBarItem.show();

        return launch;
    }
}

const vhdlLinterManager = new VhdlLinterManager();

export {
    vhdlLinterManager
};
