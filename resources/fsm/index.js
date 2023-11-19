/* eslint-disable @typescript-eslint/naming-convention */
const fs = require("fs");
const fspath  = require("path");
const vscode  = require("vscode");
const parse   = require("./utils/fsm_parser");

function getLanguageId(path) {
    let vhdlExtensions = [".vhd",".vhdl",".vho",".vht"];
    let vlogExtensions = [".v",".V",".vh",".vl"];
    let svlogExtensions = [".sv",".SV"];
    let value = fspath.extname(path);
    if (vlogExtensions.includes(value)) {
        return 'verilog';
    }
    else if (svlogExtensions.includes(value)) {
        return 'systemverilog';
    }
    else if (vhdlExtensions.includes(value)) {
        return 'vhdl';
    }
    return null;
}

class FsmViewer {
    /**
     * 
     * @param {vscode.ExtensionContext} context 
     */
    constructor(context) {
        this.panel = undefined;
        this.sources = [];
        this.context = context;
        this.rootPath = context.extensionPath.replace(/\\/g, '/');
    }

    /**
     * CN: 打开FSM图表的 webview 网页
     * @param {*} uri 指定所需转换为图表的文件uri信息
     */
    open(uri) {
        this.current_uri = uri;
        const docPath = uri.fsPath.replace(/\\/g, '/');
        if (this.panel == undefined) {
            this.create();
        }
        this.send(docPath);
    }

    async create() {
        // Create panel
        this.panel = vscode.window.createWebviewPanel(
            'state_machine_viewer', 
            'State machine viewer', 
            vscode.ViewColumn.Two, 
            {
                enableScripts: true
            }
        );
        this.panel.onDidDispose(() => {
            // When the panel is closed, cancel any future updates to the webview content
            this.panel = undefined;
        }, null, this.context.subscriptions);
        // Handle messages from the webview
        this.panel.webview.onDidReceiveMessage((message) => {
            switch (message.command) {
                case 'export':
                    this.export_as(message.text);
                    return;
                case 'go_to_state':
                    this.go_to_state(message.stm_index, message.state);
                    return;
                case 'go_to_condition':
                    this.go_to_condition(message.stm_index, message.transition, message.condition);
                    return;
            }
        }, undefined, this.context.subscriptions);
        let previewHtml = this.getWebviewContent(this.context);
        this.panel.webview.html = previewHtml;
    }

    async send(path) {
        let languageId = getLanguageId(path);
        let content = fs.readFileSync(path, "utf-8");
        let state_machines = await parse(languageId, content);
        this.state_machines = state_machines;
        this.panel.webview.postMessage({ 
            command: "update", 
            svg: state_machines.svg, 
            stms: state_machines.stm 
        });
    }

    go_to_state(stm_index, state) {
        if (this.state_machines === undefined) {
            return;
        }
        let states = this.state_machines.stm[stm_index].states;
        let state_stm;
        for (let i = 0; i < states.length; ++i) {
            if (states[i].name.replace(/\"/g, '').replace(/\'/g, '') === state) {
                state_stm = states[i];
            }
        }
        if (state_stm !== undefined) {
            let start_position = state_stm.start_position;
            let end_position = state_stm.end_position;
            let pos_1 = new vscode.Position(start_position[0], start_position[1]);
            let pos_2 = new vscode.Position(end_position[0], end_position[1]);
            vscode.workspace.openTextDocument(this.current_uri).then(doc => {
                vscode.window.showTextDocument(doc, vscode.ViewColumn.One).then(editor => {
                    // Line added - by having a selection at the same position twice, the cursor jumps there
                    editor.selections = [new vscode.Selection(pos_1, pos_2)];
                    // And the visible range jumps there too
                    var range = new vscode.Range(pos_1, pos_2);
                    editor.revealRange(range);
                });
            });
        }
    }

    go_to_condition(stm_index, transition, condition) {
        let normalized_condition = this.normalize_string(condition);
        let state_origen = transition[0];
        let state_destination = transition[1];
        if (this.state_machines === undefined) {
            return;
        }
        let states = this.state_machines.stm[stm_index].states;
        let transition_match;
        //Search state
        for (let i = 0; i < states.length; ++i) {
            if (states[i].name.replace(/\"/g, '').replace(/\'/g, '') === state_origen) {
                let transitions = states[i].transitions;
                //Search condition
                for (let j = 0; j < transitions.length; ++j) {
                    let normalized_condition_state = this.normalize_string(transitions[j].condition);
                    if (transitions[j].destination.replace(/\"/g, '').replace(/\'/g, '') === state_destination
                        && normalized_condition_state === normalized_condition) {
                        transition_match = transitions[j];
                    }
                }
            }
        }
        if (transition_match !== undefined) {
            if (transition_match.start_position === undefined || transition_match.end_position === undefined) {
                return;
            }
            let start_position = transition_match.start_position;
            let end_position = transition_match.end_position;
            let pos_1 = new vscode.Position(start_position[0], start_position[1]);
            let pos_2 = new vscode.Position(end_position[0], end_position[1]);
            vscode.workspace.openTextDocument(this.current_uri).then(doc => {
                vscode.window.showTextDocument(doc, vscode.ViewColumn.One).then(editor => {
                    // Line added - by having a selection at the same position twice, the cursor jumps there
                    editor.selections = [new vscode.Selection(pos_1, pos_2)];
                    // And the visible range jumps there too
                    var range = new vscode.Range(pos_1, pos_2);
                    editor.revealRange(range);
                });
            });
        }
    }

    export_as(type) {
        if (type === "svg") {
            let filter = { 'svg': ['svg'] };
            vscode.window.showSaveDialog({ filters: filter }).then(fileInfos => {
                if ((fileInfos === null || fileInfos === void 0 ? void 0 : fileInfos.path) !== undefined) {
                    let path_full = this.normalize_path(fileInfos === null || fileInfos === void 0 ? void 0 : fileInfos.path);
                    let dir_name = fspath.dirname(path_full);
                    let file_name = fspath.basename(path_full).split('.')[0];
                    for (let i = 0; i < this.state_machines.svg.length; ++i) {
                        let custom_path = `${dir_name}${fspath.sep}${file_name}_${i}.svg`;
                        fs.writeFileSync(custom_path, this.state_machines.svg[i].svg);
                    }
                    vscode.window.showInformationMessage('Documentation has been saved.');
                }
            });
        }
        else {
            console.log("Error export documentation.");
        }
    }

    normalize_path(path) {
        if (path[0] === '/' && require('os').platform() === 'win32') {
            return path.substring(1);
        }
        else {
            return path;
        }
    }

    normalize_string(str) {
        let n_string = str.replace(/[^ -~]+/g, '');
        n_string = n_string.replace(/ /g, '');
        n_string = n_string.replace(/\n/g, '');
        return n_string;
    }

    getWebviewContent() {
        const resource_path = fspath.join(this.rootPath, 'resources', 'fsm', 'view', 'fsm_viewer.html');
        const dir_path = fspath.dirname(resource_path);
        
        let html = fs.readFileSync(resource_path, 'utf-8');
        html = html.replace(/(<link.+?href="|<script.+?src="|<img.+?src=")(.+?)"/g, (m, $1, $2) => {
            const absLocalPath = fspath.resolve(dir_path, $2);
            const webviewUri = this.panel.webview.asWebviewUri(vscode.Uri.file(absLocalPath));
            const replaceHref = $1 + webviewUri.toString() + '"';
            return replaceHref;
        });
        return html;
    }
}
module.exports = {
    FsmViewer
};
