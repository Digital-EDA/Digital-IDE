import * as vscode from 'vscode';
import { LspOutput, ReportType } from '../../../global';
import { HdlLangID } from '../../../global/enum';
import { BaseLinter, BaseManager } from './base';
import { defaultVlogLinter } from './default';
import { modelsimLinter } from './modelsim';
import { vivadoLinter } from './vivado';
import { hdlFile, hdlPath } from '../../../hdlFs';
import { isVerilogFile } from '../../../hdlFs/file';

class VlogLinterManager implements BaseManager {
    currentLinter: BaseLinter | undefined;
    activateList: Map<string, boolean> = new Map<string, boolean>();
    activateLinterName: string;
    statusBarItem: vscode.StatusBarItem;

    constructor() {
        this.activateList.set('vivado', false);
        this.activateList.set('modelsim', false);
        this.activateList.set('default', false);
        this.activateLinterName = 'default';

        // make a status bar for rendering
        this.statusBarItem = vscode.window.createStatusBarItem(vscode.StatusBarAlignment.Right);
        this.statusBarItem.command = 'digital-ide.lsp.vlog.linter.pick';

        // when changing file, hide if langID is not verilog
        vscode.window.onDidChangeActiveTextEditor(editor => {
            if (!editor) {
                return;
            }
            const currentFileName = hdlPath.toSlash(editor.document.fileName);
                        
            if (isVerilogFile(currentFileName)) {
                this.statusBarItem.show();
            } else {
                this.statusBarItem.hide();
            }
        });

        // update when user's config is changed
        vscode.workspace.onDidChangeConfiguration(() => {
            const diagnostor = this.getUserDiagnostorSelection();
            const lastDiagnostor = this.activateLinterName;
            if (diagnostor !== lastDiagnostor) {
                LspOutput.report(`<vlog lsp manager> detect linter setting changes, switch ${lastDiagnostor} to ${diagnostor}.`, );
                this.updateLinter(); 
            }
        });
    }

    async initialise(): Promise<void> {
        const success = await this.updateLinter();
        if (!success) {
            return;
        }

        for (const doc of vscode.workspace.textDocuments) {
            const fileName = hdlPath.toSlash(doc.fileName);
            if (hdlFile.isVerilogFile(fileName)) {
                await this.lint(doc);
            }
        }
        LspOutput.report('<vlog lsp manager> finish initialization of vlog linter. Linter name: ' + this.activateLinterName, ReportType.Launch);
    }

    async lint(document: vscode.TextDocument) {
        await this.currentLinter?.lint(document);
    }

    async remove(uri: vscode.Uri): Promise<void> {
        this.currentLinter?.remove(uri);
    }

    public getUserDiagnostorSelection() {
        const vlogLspConfig = vscode.workspace.getConfiguration('digital-ide.function.lsp.linter.vlog');
        const diagnostor = vlogLspConfig.get('diagnostor', 'default');
        return diagnostor;
    }

    public async updateLinter() {
        const diagnostor = this.getUserDiagnostorSelection();
        switch (diagnostor) {
            case 'vivado':    return this.activateVivado();
            case 'modelsim':  return this.activateModelsim();
            case 'default':   return this.activateDefault();
            default:          return this.activateDefault();
        }
    }

    public async activateVivado(): Promise<boolean> {
        const selectedLinter = vivadoLinter;
        let launch = true;

        if (this.activateList.get('vivado') === false) {
            launch = await selectedLinter.initialise(HdlLangID.Verilog);
            if (launch) {
                this.statusBarItem.text = '$(getting-started-beginner) Linter(Vivado)';

                this.activateList.set('vivado', true);
                LspOutput.report('<vlog lsp manager> vivado linter has been activated', ReportType.Info);
            } else {
                this.statusBarItem.backgroundColor = new vscode.ThemeColor('statusBarItem.warningBackground');
                this.statusBarItem.tooltip = 'Fail to launch vivado linter';
                this.statusBarItem.text = '$(extensions-warning-message) Linter(vivado)';

                LspOutput.report('<vlog lsp manager> Fail to launch vivado linter', ReportType.Error);
            }
        }

        this.currentLinter = selectedLinter;
        this.activateLinterName = 'vivado';
        this.statusBarItem.show();

        return launch;
    }

    public async activateModelsim(): Promise<boolean> {
        const selectedLinter = modelsimLinter;
        let launch = true;

        if (this.activateList.get('modelsim') === false) {
            launch = await selectedLinter.initialise(HdlLangID.Verilog);
            if (launch) {
                this.statusBarItem.text = '$(getting-started-beginner) Linter(modelsim)';

                this.activateList.set('modelsim', true);
                LspOutput.report('<vlog lsp manager> modelsim linter has been activated', ReportType.Info);
            } else {
                this.statusBarItem.backgroundColor = new vscode.ThemeColor('statusBarItem.warningBackground');
                this.statusBarItem.tooltip = 'Fail to launch modelsim linter';
                this.statusBarItem.text = '$(extensions-warning-message) Linter(modelsim)';

                LspOutput.report('<vlog lsp manager> Fail to launch modelsim linter', ReportType.Error);
            }


        }

        this.currentLinter = selectedLinter;
        this.activateLinterName = 'modelsim';
        this.statusBarItem.show();

        return launch;
    }

    public async activateDefault(): Promise<boolean> {
        const selectedLinter = defaultVlogLinter;
        let launch = true;

        if (this.activateList.get('default') === false) {
            if (launch) {
                this.statusBarItem.text = '$(getting-started-beginner) Linter(default)';
                
                this.activateList.set('default', true);
                LspOutput.report('<vlog lsp manager> default build-in linter has been activated', ReportType.Info);
            } else {
                this.statusBarItem.backgroundColor = undefined;
                this.statusBarItem.tooltip = 'Fail to launch default linter';
                this.statusBarItem.text = '$(extensions-warning-message) Linter(default)';

                LspOutput.report('<vlog lsp manager> Fail to launch default linter', ReportType.Error);
            }
        }

        this.currentLinter = selectedLinter;
        this.activateLinterName = 'default';
        return launch;
    }
}

const vlogLinterManager = new VlogLinterManager();

export {
    vlogLinterManager
};
