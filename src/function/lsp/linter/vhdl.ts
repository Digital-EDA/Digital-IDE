import * as vscode from 'vscode';
import { LspOutput, ReportType } from '../../../global';
import { HdlLangID } from '../../../global/enum';
import { BaseLinter, BaseManager } from './base';
import { defaultVlogLinter } from './default';
import { modelsimLinter } from './modelsim';
import { vivadoLinter } from './vivado';

class VhdlLinterManager implements BaseManager {
    currentLinter: BaseLinter | undefined;
    activateList: Map<string, boolean> = new Map<string, boolean>();
    activateLinterName: string;

    constructor() {
        this.activateList.set('vivado', false);
        this.activateList.set('modelsim', false);
        this.activateList.set('default', false);
        this.activateLinterName = 'default';

        this.updateLinter();

        // update when user's config is changed
        vscode.workspace.onDidChangeConfiguration(() => {
            const diagnostor = this.getUserDiagnostorSelection();
            const lastDiagnostor = this.activateLinterName;
            if (diagnostor !== lastDiagnostor) {
                LspOutput.report(`[vhdl lsp manager] detect linter setting changes, switch ${lastDiagnostor} to ${diagnostor}.`, );
                this.updateLinter(); 
            }
        });
    }

    async initialise(): Promise<void> {
         
    }

    public getUserDiagnostorSelection() {
        const vlogLspConfig = vscode.workspace.getConfiguration('function.lsp.linter.vlog');
        const diagnostor = vlogLspConfig.get('diagnostor', 'default');
        return diagnostor;
    }

    public updateLinter() {
        const diagnostor = this.getUserDiagnostorSelection();
        switch (diagnostor) {
            case 'vivado':    this.activateVivado(); break;
            case 'modelsim':  this.activateModelsim(); break;
            case 'default':   this.activateDefault(); break;
            case default:     this.activateDefault(); break;
        } 
    }

    public activateVivado() {
        const selectedLinter = vivadoLinter;

        if (this.activateList.get('vivado') === false) {
            selectedLinter.initialise(HdlLangID.Verilog);
            this.activateList.set('vivado', true);
            LspOutput.report('[vhdl lsp manager] vivado linter has been activated', ReportType.Info);
        }

        this.currentLinter = selectedLinter;
        this.activateLinterName = 'vivado';
    }

    public activateModelsim() {
        const selectedLinter = modelsimLinter;

        if (this.activateList.get('modelsim') === false) {
            selectedLinter.initialise(HdlLangID.Verilog);
            this.activateList.set('modelsim', true);
            LspOutput.report('[vhdl lsp manager] modelsim linter has been activated', ReportType.Info); 
        }

        this.currentLinter = selectedLinter;
        this.activateLinterName = 'modelsim';
    }

    public activateDefault() {
        const selectedLinter = defaultVlogLinter;

        if (this.activateList.get('default') === false) {
            
            this.activateList.set('default', true);
            LspOutput.report('[vhdl lsp manager] default build-in linter has been activated', ReportType.Info);
        }

        this.currentLinter = selectedLinter;
        this.activateLinterName = 'default';
    }
}

const vhdlLinterManager = new VhdlLinterManager();

export {
    vhdlLinterManager
};
