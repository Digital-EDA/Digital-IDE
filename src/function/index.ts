import * as vscode from 'vscode';
import * as path from 'path';

import * as hdlDoc from './hdlDoc';
import * as sim from './sim';
import * as treeView from './treeView';

import * as lspCompletion from './lsp/completion';
import * as lspFormatter from '../../resources/formatter';
import * as lspTranslator from '../../resources/translator';
import * as lspLinter from './lsp/linter';

import * as tool from './tool';

// special function
import * as FSM from './fsm';
import * as Netlist from './netlist';
import * as WaveView from './dide-viewer';
import { ModuleDataItem } from './treeView/tree';
import { downloadLsp } from './lsp-client';

function registerDocumentation(context: vscode.ExtensionContext) {
    vscode.commands.registerCommand('digital-ide.hdlDoc.showWebview', hdlDoc.showDocWebview);
    hdlDoc.registerFileDocExport(context);
    hdlDoc.registerProjectDocExport(context);
}

function registerSimulation(context: vscode.ExtensionContext) {
    vscode.commands.registerCommand('digital-ide.tool.instance', sim.instantiation);
    vscode.commands.registerCommand('digital-ide.tool.testbench', sim.testbench);
    vscode.commands.registerCommand('digital-ide.tool.icarus.simulateFile', (view: ModuleDataItem) => {
        sim.Icarus.simulateFile(view);
    });
}

function registerFunctionCommands(context: vscode.ExtensionContext) {
    registerDocumentation(context);
    registerSimulation(context);
    registerTreeView(context);
}

function registerTreeView(context: vscode.ExtensionContext) {
    // register normal tree
    vscode.window.registerTreeDataProvider('digital-ide-treeView-arch', treeView.moduleTreeProvider);
    vscode.window.registerTreeDataProvider('digital-ide-treeView-tool', treeView.toolTreeProvider);
    vscode.window.registerTreeDataProvider('digital-ide-treeView-hardware', treeView.hardwareTreeProvider);
    // vscode.window.registerTreeDataProvider('digital-ide-treeView-software', treeView.softwareTreeProvider);

    // constant used in tree
    vscode.commands.executeCommand('setContext', 'TOOL-tree-expand', false);

    // register command in tree
    vscode.commands.registerCommand('digital-ide.treeView.arch.expand', treeView.expandTreeView);
    vscode.commands.registerCommand('digital-ide.treeView.arch.collapse', treeView.collapseTreeView);
    vscode.commands.registerCommand('digital-ide.treeView.arch.refresh', treeView.refreshArchTree);
    vscode.commands.registerCommand('digital-ide.treeView.arch.openFile', treeView.openFileByUri);
}

function registerLsp(context: vscode.ExtensionContext, version: string) {

    // lsp download
    vscode.commands.registerCommand('digital-ide.digital-lsp.download', () => {
        const versionFolderPath = context.asAbsolutePath(
            path.join('resources', 'dide-lsp', 'server', version)
        );
        downloadLsp(context, version, versionFolderPath)
    });

    const vlogSelector: vscode.DocumentSelector = {scheme: 'file', language: 'verilog'};
    const svlogSelector: vscode.DocumentSelector = {scheme: 'file', language: 'systemverilog'};
    const vhdlSelector: vscode.DocumentSelector = {scheme: 'file', language: 'vhdl'};
    const tclSelector: vscode.DocumentSelector = {scheme: 'file', language: 'tcl'};

    // formatter
    vscode.languages.registerDocumentFormattingEditProvider(vlogSelector, lspFormatter.hdlFormatterProvider);
    vscode.languages.registerDocumentFormattingEditProvider(vhdlSelector, lspFormatter.hdlFormatterProvider);
    vscode.languages.registerDocumentFormattingEditProvider(svlogSelector, lspFormatter.hdlFormatterProvider);

    // translator
    vscode.commands.registerCommand('digital-ide.vhdl2vlog', uri => lspTranslator.vhdl2vlog(uri));

    // verilog lsp
    // vscode.languages.registerDocumentSymbolProvider(vlogSelector, lspDocSymbol.vlogDocSymbolProvider);
    // vscode.languages.registerDefinitionProvider(vlogSelector, lspDefinition.vlogDefinitionProvider);
    // vscode.languages.registerHoverProvider(vlogSelector, lspHover.vlogHoverProvider);
    // vscode.languages.registerCompletionItemProvider(vlogSelector, lspCompletion.vlogIncludeCompletionProvider, '/', '"');
    // vscode.languages.registerCompletionItemProvider(vlogSelector, lspCompletion.vlogMacroCompletionProvider, '`');
    // vscode.languages.registerCompletionItemProvider(vlogSelector, lspCompletion.vlogPositionPortProvider, '.');
    // vscode.languages.registerCompletionItemProvider(vlogSelector, lspCompletion.vlogCompletionProvider);
    // vscode.languages.registerDocumentSemanticTokensProvider(vlogSelector, lspDocSemantic.vlogDocSenmanticProvider, lspDocSemantic.vlogLegend);

    
    // vhdl lsp    
    // vscode.languages.registerDocumentSymbolProvider(vhdlSelector, lspDocSymbol.vhdlDocSymbolProvider);
    // vscode.languages.registerDefinitionProvider(vhdlSelector, lspDefinition.vhdlDefinitionProvider);
    // vscode.languages.registerHoverProvider(vhdlSelector, lspHover.vhdlHoverProvider);
    // vscode.languages.registerCompletionItemProvider(vhdlSelector, lspCompletion.vhdlCompletionProvider);
    

    // tcl lsp
    vscode.languages.registerCompletionItemProvider(tclSelector, lspCompletion.tclCompletionProvider);

    // lsp linter
    // make first symbols in workspace
    lspLinter.vlogLinterManager.initialise();
    lspLinter.vhdlLinterManager.initialise();
    lspLinter.svlogLinterManager.initialise();

    vscode.commands.registerCommand('digital-ide.lsp.vlog.linter.pick', lspLinter.pickVlogLinter);
    vscode.commands.registerCommand('digital-ide.lsp.vhdl.linter.pick', lspLinter.pickVhdlLinter);
    vscode.commands.registerCommand('digital-ide.lsp.svlog.linter.pick', lspLinter.pickSvlogLinter);
}


function registerToolCommands(context: vscode.ExtensionContext) {
    vscode.commands.registerCommand('digital-ide.lsp.tool.insertTextToUri', tool.insertTextToUri);
    vscode.commands.registerCommand('digital-ide.lsp.tool.transformOldPropertyFile', tool.transformOldPpy);
    vscode.commands.registerCommand('digital-ide.tool.export-filelist', (view: ModuleDataItem) => {
        tool.exportFilelist(view);
    });
}

function registerFSM(context: vscode.ExtensionContext) {
    vscode.commands.registerCommand('digital-ide.fsm.show', uri => FSM.openFsmViewer(context, uri));
}

function registerNetlist(context: vscode.ExtensionContext) {
    vscode.commands.registerCommand('digital-ide.netlist.show', uri => Netlist.openNetlistViewer(context, uri));
}

function registerWaveViewer(context: vscode.ExtensionContext) {
    vscode.commands.registerCommand('digital-ide.waveviewer.show', uri => WaveView.openWaveViewer(context, uri));

    // 通过 customEditors 来配置
    const vcdViewerProvider = new WaveView.VcdViewerProvider(context);
    vscode.window.registerCustomEditorProvider('digital-ide.vcd.viewer', vcdViewerProvider,
        {
            webviewOptions: {
                retainContextWhenHidden: true,
            },
            supportsMultipleEditorsPerDocument: false
        }
    );
}

export {
    registerFunctionCommands,
    registerLsp,
    registerToolCommands,
    registerFSM,
    registerNetlist,
    registerWaveViewer
};