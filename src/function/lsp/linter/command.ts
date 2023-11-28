import * as vscode from 'vscode';

import { vivadoLinter } from './vivado';
import { modelsimLinter } from './modelsim';
import { verilatorLinter } from './verilator';
import { HdlLangID } from '../../../global/enum';
import { vlogLinterManager } from './vlog';
import { vhdlLinterManager } from './vhdl';
import { easyExec } from '../../../global/util';
import { LspOutput } from '../../../global';

let _selectVlogLinter: string | null = null;
let _selectVhdlLinter: string | null = null;

interface LinterItem extends vscode.QuickPickItem {
    name: string
    available: boolean
}

async function makeDefaultPickItem(): Promise<LinterItem> {
    return {
        label: '$(getting-started-beginner) default',
        name: 'default',
        available: true,
        description: 'Digital-IDE build in diagnostic tool',
        detail: 'inner build is ready'
    };
}

async function makeVivadoPickItem(langID: HdlLangID): Promise<LinterItem> {
    const executablePath = vivadoLinter.getExecutableFilePath(langID);
    const linterName = vivadoLinter.executableFileMap.get(langID);
    if (executablePath) {
        const { stderr } = await easyExec(executablePath, []);
        if (stderr.length > 0) {
            return {
                label: '$(extensions-warning-message) vivado',
                name: 'vivado',
                available: false,
                description: `vivado diagnostic tool ${linterName}`,
                detail: `${executablePath} is not available`
            };
        }
    }
    return {
        label: '$(getting-started-beginner) vivado',
        name: 'vivado',
        available: true,
        description: `vivado diagnostic tool ${linterName}`,
        detail: `${executablePath} is ready`
    };
}

async function makeModelsimPickItem(langID: HdlLangID): Promise<LinterItem> {
    const executablePath = modelsimLinter.getExecutableFilePath(langID);
    const linterName = modelsimLinter.executableFileMap.get(langID);
    if (executablePath) {
        const { stderr } = await easyExec(executablePath, []);
        if (stderr.length > 0) {
            return {
                label: '$(extensions-warning-message) modelsim',
                name: 'modelsim',
                available: false,
                description: `modelsim diagnostic tool ${linterName}`,
                detail: `${executablePath} is not available`
            };
        }
    }
    return {
        label: '$(getting-started-beginner) modelsim',
        name: 'modelsim',
        available: true,
        description: `modelsim diagnostic tool ${linterName}`,
        detail: `${executablePath} is ready`
    };
}

async function pickVlogLinter() {
    const pickWidget = vscode.window.createQuickPick<LinterItem>();
    pickWidget.placeholder = 'select a linter for verilog code diagnostic';
    pickWidget.canSelectMany = false;

    await vscode.window.withProgress({
        location: vscode.ProgressLocation.Notification,
        title: 'Parsing local environment ...',
        cancellable: true
    }, async () => {
        pickWidget.items = [
            await makeDefaultPickItem(),
            await makeVivadoPickItem(HdlLangID.Verilog),
            await makeModelsimPickItem(HdlLangID.Verilog)
        ];
    });
    
    pickWidget.onDidChangeSelection(items => {
        const selectedItem = items[0];
        _selectVlogLinter = selectedItem.name;
    });

    pickWidget.onDidAccept(() => {
        if (_selectVlogLinter) {
            const vlogLspConfig = vscode.workspace.getConfiguration('digital-ide.function.lsp.linter.vlog');
            vlogLspConfig.update('diagnostor', _selectVlogLinter);
            pickWidget.hide();
        }
    });

    pickWidget.show();
}

async function pickVhdlLinter() {
    const pickWidget = vscode.window.createQuickPick<LinterItem>();
    pickWidget.placeholder = 'select a linter for code diagnostic';
    pickWidget.canSelectMany = false;

    await vscode.window.withProgress({
        location: vscode.ProgressLocation.Notification,
        title: 'Parsing local environment ...',
        cancellable: true
    }, async () => {
        pickWidget.items = [
            await makeDefaultPickItem(),
            await makeVivadoPickItem(HdlLangID.Vhdl),
            await makeModelsimPickItem(HdlLangID.Vhdl)
        ];
    });
    
    pickWidget.onDidChangeSelection(items => {
        const selectedItem = items[0];
        _selectVlogLinter = selectedItem.name;
    });

    pickWidget.onDidAccept(() => {
        if (_selectVlogLinter) {
            const vlogLspConfig = vscode.workspace.getConfiguration('digital-ide.function.lsp.linter.vhdl');
            vlogLspConfig.update('diagnostor', _selectVlogLinter);
            pickWidget.hide();
        }
    });

    pickWidget.show();
}



export {
    pickVlogLinter,
    pickVhdlLinter
};