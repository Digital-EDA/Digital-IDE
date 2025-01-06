import * as vscode from 'vscode';
import * as path from 'path';

import * as hdlDoc from './dide-doc';
import * as sim from './sim';
import * as treeView from './treeView';

import { tclCompletionProvider } from './lsp/completion/tcl';
import * as lspFormatter from '../../resources/formatter';
import * as lspTranslator from '../../resources/translator';

import * as tool from './tool';

// special function
import * as FSM from './fsm';
import * as Netlist from './dide-netlist';
import * as WaveView from './dide-viewer';
import { ModuleDataItem } from './treeView/tree';
import { downloadLsp } from './lsp-client';
import { hdlPath } from '../hdlFs';

function registerDocumentation(context: vscode.ExtensionContext) {
    vscode.commands.registerCommand('digital-ide.hdlDoc.showWebview', async (uri: vscode.Uri) => {
        const standardPath = hdlPath.toSlash(uri.fsPath);
        const item = hdlDoc.docManager.get(standardPath);
        if (item) {
            // 展示 webview
            item.panel.reveal(vscode.ViewColumn.Two);
        } else {
            const panel = await hdlDoc.makeDocWebview(uri, context);
            // TODO: 注册文件变动监听
            const fileChangeDisposer = vscode.window.onDidChangeActiveTextEditor(async event => {
                // const client = LspClient.DigitalIDE;
                // if (client && event?.document && client.state === State.Running && event.document.uri.path === uri.path) {
                //     const path = hdlPath.toSlash(event.document.fileName);
                //     const fileType = 'common';
                //     const toolChain = opeParam.prjInfo.toolChain as DoFastToolChainType;
                //     const fast = await client.sendRequest(SyncFastRequestType, { path, fileType, toolChain });
                //     if (fast) {
                //         const renderBody = await makeDocBody(uri, 'webview');                
                //         panel.webview.postMessage({
                //             command: 'do-render',
                //             body: renderBody
                //         });
                //     }
                // }
            });
            hdlDoc.docManager.set(standardPath, { panel, fileChangeDisposer });
            panel.onDidDispose(event => {
                hdlDoc.docManager.delete(standardPath);
                fileChangeDisposer.dispose();
            });
        }
    });
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

function registerTreeViewDataProvider(context: vscode.ExtensionContext) {
    vscode.window.registerTreeDataProvider('digital-ide-treeView-hardware', treeView.hardwareTreeProvider);
    // vscode.window.registerTreeDataProvider('digital-ide-treeView-software', treeView.softwareTreeProvider);
    
    vscode.window.registerTreeDataProvider('digital-ide-treeView-arch', treeView.moduleTreeProvider);
    // vscode.window.registerTreeDataProvider('digital-ide-treeView-tool', treeView.toolTreeProvider);
}

function registerTreeView(context: vscode.ExtensionContext) {
    // constant used in tree
    vscode.commands.executeCommand('setContext', 'TOOL-tree-expand', false);

    // register command in tree
    vscode.commands.registerCommand('digital-ide.treeView.arch.expand', treeView.expandTreeView);
    vscode.commands.registerCommand('digital-ide.treeView.arch.collapse', treeView.collapseTreeView);
    vscode.commands.registerCommand('digital-ide.treeView.arch.refresh', treeView.refreshArchTree);
    vscode.commands.registerCommand('digital-ide.treeView.arch.openFile', treeView.openFileByUri);
    vscode.commands.registerCommand('digital-ide.tool.clean', treeView.clean);
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

    // tcl lsp
    vscode.languages.registerCompletionItemProvider(tclSelector, tclCompletionProvider);
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
    context.subscriptions.push(
        vscode.commands.registerCommand('digital-ide.netlist.show', (uri, moduleName) => {
            if (typeof uri === 'string') {
                uri = vscode.Uri.file(uri);
            }
            Netlist.openNetlistViewer(context, uri, moduleName);
        })
    );

    context.subscriptions.push(
        vscode.commands.registerCommand('digital-ide.netlist.run-ys', (uri: vscode.Uri) => {
            Netlist.runYsScript(context, uri);
        })
    )
    
    context.subscriptions.push(
        vscode.commands.registerCommand('digital-ide.netlist.treeview', (view: ModuleDataItem) => {
            if (view.path && view.name) {
                const uri = vscode.Uri.file(view.path);
                Netlist.openNetlistViewer(context, uri, view.name);
            }
        })
    );
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
    registerWaveViewer,
    registerTreeViewDataProvider
};