import * as vscode from 'vscode';
import { LspOutput, ReportType } from '../../../global';
import { HdlLangID } from '../../../global/enum';
import { BaseLinter, BaseManager } from './base';
import { defaultVlogLinter } from './default';
import { modelsimLinter } from './modelsim';
import { vivadoLinter } from './vivado';
import { hdlFile, hdlPath } from '../../../hdlFs';

class VhdlLinterManager implements BaseManager {
    currentLinter: BaseLinter | undefined;
    activateList: Map<string, boolean> = new Map<string, boolean>();
    activateLinterName: string;

    constructor() {
        this.activateList.set('vivado', false);
        this.activateList.set('modelsim', false);
        this.activateList.set('default', false);
        this.activateLinterName = 'default';

        // update when user's config is changed
        vscode.workspace.onDidChangeConfiguration(() => {
            const diagnostor = this.getUserDiagnostorSelection();
            const lastDiagnostor = this.activateLinterName;
            if (diagnostor !== lastDiagnostor) {
                LspOutput.report(`<vhdl lsp manager> detect linter setting changes, switch ${lastDiagnostor} to ${diagnostor}.`, );
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
            if (hdlFile.isVhdlFile(fileName)) {
                await this.lint(doc);
            }
        }
        LspOutput.report('<vhdl lsp manager> finish initialization of vhdl linter. Linter name: ' + this.activateLinterName, ReportType.Launch);
    }

    async lint(document: vscode.TextDocument) {
        await this.currentLinter?.lint(document);
    }
    
    async remove(uri: vscode.Uri): Promise<void> {
        this.currentLinter?.remove(uri);
    }

    public getUserDiagnostorSelection() {
        const vlogLspConfig = vscode.workspace.getConfiguration('function.lsp.linter.vlog');
        const diagnostor = vlogLspConfig.get('diagnostor', 'default');
        return diagnostor;
    }

    public async updateLinter(): Promise<boolean> {
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
            this.activateList.set('vivado', true);
            LspOutput.report('<vhdl lsp manager> vivado linter has been activated', ReportType.Info);
        }

        this.currentLinter = selectedLinter;
        this.activateLinterName = 'vivado';
        return launch;
    }

    public async activateModelsim(): Promise<boolean> {
        const selectedLinter = modelsimLinter;
        let launch = true;

        if (this.activateList.get('modelsim') === false) {
            launch = await selectedLinter.initialise(HdlLangID.Verilog);
            this.activateList.set('modelsim', true);
            LspOutput.report('<vhdl lsp manager> modelsim linter has been activated', ReportType.Info); 
        }

        this.currentLinter = selectedLinter;
        this.activateLinterName = 'modelsim';
        return launch;
    }

    public async activateDefault(): Promise<boolean> {
        const selectedLinter = defaultVlogLinter;
        let launch = true;

        if (this.activateList.get('default') === false) {
            
            this.activateList.set('default', true);
            LspOutput.report('<vhdl lsp manager> default build-in linter has been activated', ReportType.Info);
        }

        this.currentLinter = selectedLinter;
        this.activateLinterName = 'default';
        return launch;
    }
}

const vhdlLinterManager = new VhdlLinterManager();

export {
    vhdlLinterManager
};
