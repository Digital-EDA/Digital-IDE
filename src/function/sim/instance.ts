import * as vscode from 'vscode';
import { HdlLangID } from '../../global/enum';
import { hdlParam } from '../../hdlParser';
import { HdlModulePort, HdlModuleParam, HdlModulePortType } from '../../hdlParser/common';
import { HdlModule } from '../../hdlParser/core';

class ModuleInfoItem {
    label: string;
    description: string;
    detail: string;
    module: HdlModule;
    /**
     * @param module
     */
    constructor(module: HdlModule) {
        // TODO : 等到sv的解析做好后，写入对于不同hdl的图标
        let iconID = '$(instance-' + module.file.languageId + ') ';
        this.label = iconID + module.name;
        this.description = module.params.length + ' $(instance-param) ' + 
                           module.ports.length + ' $(instance-port) ' + 
                           module.getInstanceNum() + ' $(instance-module)';
        this.detail = module.path;
        this.module = module;
    }
};

/**
 * @description verilog模式下生成整个例化的内容
 * @param module 模块信息
 */
function instanceVlogCode(module: HdlModule, prefix: string = '', returnSnippetString: boolean = false): string {
    const instantiationConfig = vscode.workspace.getConfiguration('digital-ide.function.instantiation');
    const needComment = instantiationConfig.get('addComment', true);
    const autoNetOutputDeclaration = instantiationConfig.get('autoNetOutputDeclaration', true);

    const content = new vscode.SnippetString();

    // make net declaration if needed
    if (autoNetOutputDeclaration) {
        const netDeclarationString = makeNetOutputDeclaration(module.ports, prefix, needComment);
        if (netDeclarationString) {
            content.appendText(netDeclarationString);
        }
    }

    content.appendText(prefix + module.name + ' ');
    makeVlogParamAssignments(content, module.params, prefix, returnSnippetString, needComment);

    if (returnSnippetString) {
        content.appendPlaceholder('u_' + module.name);
    } else {
        content.appendText('u_' + module.name);
    }

    makeVlogPortAssignments(content, module.ports, prefix, returnSnippetString, needComment);

    const instanceString = content.value;
    return instanceString;
}

/**
 * @description vhdl模式下生成整个例化的内容
 * @param module 模块信息
 */
function instanceVhdlCode(module: HdlModule) {
    // module 2001 style
    let port = vhdlPort(module.ports);
    let param = vhdlParam(module.params);

    let instContent = `u_${module.name} : ${module.name}\n`;

    if (param !== '') {
        instContent += `generic map(\n${param})\n`;
    }

    instContent += `port map(\n${port});\n`;

    return instContent;
}

function makeNetOutputDeclaration(ports: HdlModulePort[], prefix: string, needComment: boolean): string | null {
    const maxWidthLength = Math.max(...ports.map(p => p.width.length));

    let netOutputDeclaration = prefix + (needComment ? '// outports wire\n' : '');
    let haveOutput = false;
    for (const port of ports) {
        if (port.type === HdlModulePortType.Output) {
            haveOutput = true;
            let portWidth = port.width ? port.width : '';
            if (portWidth === 'Unknown' || portWidth === '1') {
                portWidth = '';
            }
            portWidth += ' '.repeat(maxWidthLength - portWidth.length + 1);
            const netDeclaration = prefix + `wire ${portWidth}\t${port.name};\n`;
            netOutputDeclaration += netDeclaration;
        }
    }

    if (!haveOutput) {
        return null;
    } else {
        netOutputDeclaration += '\n';
        return netOutputDeclaration;
    }
}

/**
 * @description verilog模式下对端口信息生成要例化的内容
 * @param ports 端口信息列表
 */
function makeVlogPortAssignments(content: vscode.SnippetString, ports: HdlModulePort[], prefix: string = '', returnSnippetString: boolean, needComment: boolean) {
    if (ports.length === 0) {
        content.appendText('();');
        return;
    }

    const maxNameLength = Math.max(...ports.map(p => p.name.length));

    content.appendText('(\n');

    for (let i = 0; i < ports.length; ++ i) {
        const port = ports[i];
        const paddingName = port.name + ' '.repeat(maxNameLength - port.name.length + 1);   

        content.appendText(prefix + '\t.' + paddingName + '\t( ');
        if (returnSnippetString) {
            content.appendPlaceholder(port.name);
        } else {
            content.appendText(port.name);
        }
        content.appendText(' '.repeat(maxNameLength - port.name.length + 1) + ' )');
        if (i < ports.length - 1) {
            content.appendText(',');
        }
        content.appendText('\n');
    }

    content.appendText(prefix + ');\n');
}


/**
 * @description verilog模式下对参数信息生成要例化的内容
 * @param params 参数信息列表
 */
function makeVlogParamAssignments(content: vscode.SnippetString, params: HdlModuleParam[], prefix: string = '', returnSnippetString: boolean, needComment: boolean) {
    if (params.length === 0) {
        return;
    }

    const maxNameLength = Math.max(...params.map(p => p.name.length));
    const maxInitLength = Math.max(...params.map(p => p.init.length));

    content.appendText('#(\n');

    // .NAME  ( INIT  ),
    for (let i = 0; i < params.length; ++ i) {
        const param = params[i];
        const paddingName = param.name + ' '.repeat(maxNameLength - param.name.length + 1);
        content.appendText(prefix + '\t.' + paddingName + '\t( ');
        if (returnSnippetString) {
            content.appendPlaceholder(param.init);
        } else {
            content.appendText(param.init);
        }
        content.appendText(' '.repeat(maxInitLength - param.init.length + 1) + ' )');
        if (i < params.length - 1) {
            content.appendText(',');
            content.appendText('\n');
        }
    }
    content.appendText(prefix + ')\n');
}

/**
 * @description vhdl模式下对端口信息生成要例化的内容
 * @param ports 端口信息列表
 */
function vhdlPort(ports: HdlModulePort[]): string {
    let nmax = getlmax(ports, 'name');
    
    // NAME => NAME,
    let portStr = `\n\t-- ports\n`;
    for (let i = 0; i < ports.length; i++) {
        let name = ports[i].name;
        let padding = nmax - name.length + 1;
        name += ' '.repeat(padding);
        portStr += `\t${name} => ${name}`;
        if (i !== (ports.length - 1)) {
            portStr += ',';
        }
        portStr += '\n';
    }
    return portStr;
}

/**
 * @description vhdl模式下对参数信息生成要例化的内容
 * @param params 参数信息列表
 */
function vhdlParam(params: HdlModuleParam[]): string {
    let paramStr = '';
    let nmax = getlmax(params, 'name');

    // NAME => NAME,
    for (let i = 0; i < params.length; i++) {
        let name = params[i].name;
        const init = params[i].init;

        let npadding = nmax - name.length + 1;
        name += ' '.repeat(npadding);

        paramStr += `\t${name} => ${init}`;
        if (i !== (params.length - 1)) {
            paramStr += ',';
            paramStr += '\n';
        }
    }
    return paramStr;
}

/**
 * @description 在arr中找到pro属性的最大字符长度
 * @param {Array}  arr 待查找的数组
 * @param {String} pro 指定属性
 * @returns {Number} 该数组中的pro属性的最大字符长度
 */
function getlmax(arr: any[], pro: string): number {
    let lmax = 0;
    for (let i = 0; i < arr.length; i++) {
        const len = arr[i][pro].length;
        if (len <= lmax) {
            continue;
        }
        lmax = len;
    }
    return lmax;
}

/**
 * @description 向光标处插入内容
 * @param content 需要插入的内容
 * @param editor  通过 vscode.window.activeTextEditor 获得
 */
function selectInsert(content: string, editor: vscode.TextEditor): boolean {
    if (editor === undefined) {
        return false;
    }
    let selections = editor.selections;
    editor.edit((editBuilder) => {
        selections.forEach((selection) => {
            // position, content
            editBuilder.insert(selection.active, content);
        });
    });
    return true;
}

/**
 * @description make item for vscode.window.showQuickPick from hdlModules
 * @param modules 
 * @returns 
 */
function getSelectItem(modules: HdlModule[]) {
    // make ModuleInfoList
    const items = [];
    for (const module of modules) {
        items.push(new ModuleInfoItem(module));
    }
    return items;
}

/**
 * @description 调用vscode的窗体，让用户从所有的Module中选择模块（为后续的例化准备）
 */
async function selectModuleFromAll() {
    const option = {
        placeHolder: 'Select a Module'
    };

    const selectModuleInfo = await vscode.window.showQuickPick(
        getSelectItem(hdlParam.getAllHdlModules()), option
    );
    
    if (selectModuleInfo) {
        return selectModuleInfo.module;
    } else {
        return null;
    }
}

function instanceByLangID(module: HdlModule): string {    
    switch (module.languageId) {
        case HdlLangID.Verilog: return instanceVlogCode(module);
        case HdlLangID.Vhdl: return instanceVhdlCode(module);
        // TODO : add support for svlog
        case HdlLangID.SystemVerilog: return instanceVlogCode(module);
        default: return '';
    }
}

async function instantiation() {
    const module = await selectModuleFromAll();    
    if (module) {
        const code = instanceByLangID(module);        
        const editor = vscode.window.activeTextEditor;
        if (editor) {
            selectInsert(code, editor);
        }
    }
}

export {
    instanceVlogCode,
    instantiation,
    instanceByLangID,
    getSelectItem
};