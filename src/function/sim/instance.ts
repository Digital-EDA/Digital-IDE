import * as vscode from 'vscode';
import * as fs from 'fs';
import { HdlLangID } from '../../global/enum';
import { hdlParam } from '../../hdlParser';
import { HdlModulePort, HdlModuleParam, HdlModulePortType } from '../../hdlParser/common';
import { HdlModule } from '../../hdlParser/core';
import { hdlFile, hdlPath } from '../../hdlFs';
import { t } from '../../i18n';
import { SystemVerilogParser } from './SystemVerilogParser';


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
    const autoNetInputDeclaration = instantiationConfig.get('autoNetInputDeclaration', false);
    const instanNameTemplate = instantiationConfig.get('instanName', 'u_${moduleName}');

    const content = new vscode.SnippetString();

    // 再次解析文件
    let code :string = fs.readFileSync(module.file.path, 'utf-8');
    let svParser: SystemVerilogParser = new SystemVerilogParser(code);


    // 生成例化模块名称
    let instanceName: string;
    if (instanNameTemplate.indexOf('${moduleName}') === -1) {
        instanceName = ('u_' + module.name);
    } else {
        instanceName = instanNameTemplate.replace('${moduleName}', module.name);
    }

    // 生成端口的net声明
    if (autoNetInputDeclaration) {
        const netDeclarationString = makeNetInputDeclaration(module.ports, instanceName, prefix, needComment);
        if (netDeclarationString) {
            content.appendText(netDeclarationString);
        }
    }

    // 生成端口的net声明
    if (autoNetOutputDeclaration) {
        const netDeclarationString = makeNetOutputDeclaration(module.ports, instanceName, prefix, needComment);
        if (netDeclarationString) {
            content.appendText(netDeclarationString);
        }
    }

    // 生成例化参数内容
    content.appendText(prefix + module.name);
    // makeVlogParamAssignments(content, module.params, prefix, returnSnippetString, needComment);
    makeVlogParamAssignments_sVparse(content, svParser, prefix, returnSnippetString, needComment);
    content.appendText(prefix);

    if (returnSnippetString) {
        // content.appendPlaceholder('u_' + module.name);
        content.appendPlaceholder(instanceName);
    } else {
        // content.appendText('u_' + module.name);
        content.appendText(instanceName);
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
    let param = vhdlParam(module.params);
    let port = vhdlPort(module.ports);

    let instContent = `u_${module.name} : ${module.name}\n`;

    if (param !== '') {
        instContent += `generic map(\n${param})\n`;
    }

    instContent += `port map(\n${port.trim()}\n);\n`;

    return instContent;
}

/**
 * @brief  获取缩进字符串
 * @param  [vscode] editor
 * @return [void]
 */
function getIndentString(): string {
    const editor = vscode.window.activeTextEditor;
    if (!editor) {
        return "\t";
    }

    const config = editor.options;
    const insertSpaces = config.insertSpaces;
    const tabSize = config.tabSize;

    const useSpaces = insertSpaces === true;
    const size = typeof tabSize === 'number' && tabSize > 0 ? tabSize : 4;

    return useSpaces ? ' '.repeat(size) : '\t';
}

/**
 * @brief  检查端口声明是否存在
 * @param  [String] port 端口名称列表
 * @return [void]
 */
function checkPortDeclarationExist(ports: HdlModulePort[]): HdlModulePort[] | null {
    const editor = vscode.window.activeTextEditor;
    if (!editor) {
        return null;
    }

    if (ports.length === 0) {
        return null;
    }

    const documentText = editor.document.getText();
    const results: HdlModulePort[] = [];

    for (const p of ports) {
        const portName = p.name;

        const regex_wire = new RegExp(`\\bwire\\b\\s+.*\\b${portName}\\b`, 'm');
        const regex_reg = new RegExp(`\\breg\\b\\s+.*\\b${portName}\\b`, 'm');
        const regex_logic = new RegExp(`\\blogic\\b\\s+.*\\b${portName}\\b`, 'm');
        const regex_input = new RegExp(`\\binput\\b\\s+.*\\b${portName}\\b`, 'm');
        const regex_output = new RegExp(`\\boutput\\b\\s+.*\\b${portName}\\b`, 'm');
        const regex_inout = new RegExp(`\\binout\\b\\s+.*\\b${portName}\\b`, 'm');

        const isDeclared = regex_wire.test(documentText) ||
            regex_reg.test(documentText) ||
            regex_logic.test(documentText) ||
            regex_input.test(documentText) ||
            regex_output.test(documentText) ||
            regex_inout.test(documentText);

        if (!isDeclared) {
            results.push(p);
        }
    }
    return results;
}

function makeNetInputDeclaration(ports: HdlModulePort[], InstanceName: string, prefix: string, needComment: boolean): string | null {
    const maxWidthLength = Math.max(...ports.map(p => p.width.length));

    let netInputDeclaration = prefix + (needComment ? "\/\/ ****** " + InstanceName + " inports ******\n" : '');

    const inputPorts: HdlModulePort[] = [];
    for (const port of ports) {
        if (port.type === HdlModulePortType.Input) {
            inputPorts.push(port);
        }
    }

    const existResults = checkPortDeclarationExist(inputPorts);
    if (existResults === null || existResults.length === 0) {
        return null;
    }

    for (const port of existResults) {
        let portWidth = port.width ? port.width : '';
        if (portWidth === 'Unknown' || portWidth === '1') {
            portWidth = '';
        }
        portWidth += ' '.repeat(maxWidthLength - portWidth.length + 1);
        const netDeclaration = prefix + 'wire' + portWidth + getIndentString() + ' ' + port.name + ';\n';
        netInputDeclaration += netDeclaration;

    }

    netInputDeclaration += '\n';
    return netInputDeclaration;

}


function makeNetOutputDeclaration(ports: HdlModulePort[], InstanceName: string, prefix: string, needComment: boolean): string | null {
    const maxWidthLength = Math.max(...ports.map(p => p.width.length));

    let netOutputDeclaration = prefix + (needComment ? "\/\/ ****** " + InstanceName + " outports ******\n" : '');

    const OutputPorts: HdlModulePort[] = [];
    for (const port of ports) {
        if (port.type === HdlModulePortType.Output) {
            OutputPorts.push(port);
        }
    }

    const existResults = checkPortDeclarationExist(OutputPorts);
    if (existResults === null || existResults.length === 0) {
        return null;
    }

    for (const port of existResults) {
        let portWidth = port.width ? port.width : '';
        if (portWidth === 'Unknown' || portWidth === '1') {
            portWidth = '';
        }
        portWidth += ' '.repeat(maxWidthLength - portWidth.length + 1);
        const netDeclaration = prefix + 'wire' + portWidth + getIndentString() + ' ' + port.name + ';\n';
        netOutputDeclaration += netDeclaration;

    }

    netOutputDeclaration += '\n';
    return netOutputDeclaration;
}

/**
 * @description verilog模式下对端口信息生成要例化的内容
 * @param ports 端口信息列表
 */
function makeVlogPortAssignments(content: vscode.SnippetString, ports: HdlModulePort[], prefix: string = '', returnSnippetString: boolean, needComment: boolean) {
    if (ports.length === 0) {
        content.appendText(' ();');
        return;
    }

    const maxNameLength = Math.max(...ports.map(p => p.name.length));

    content.appendText(' (\n');

    for (let i = 0; i < ports.length; ++i) {
        const port = ports[i];
        const paddingName = port.name + ' '.repeat(maxNameLength - port.name.length + 1);

        content.appendText(prefix + getIndentString() + '.' + paddingName + getIndentString() + '(');
        if (returnSnippetString) {
            content.appendPlaceholder(port.name);
        } else {
            content.appendText(port.name);
        }
        content.appendText(' '.repeat(maxNameLength - port.name.length) + ')');
        if (i < ports.length - 1) {
            content.appendText(',');
        }
        content.appendText('\n');
    }

    content.appendText(prefix + ');\n');
}

function makeVlogParamAssignments_sVparse(content: vscode.SnippetString, sVpars: SystemVerilogParser, prefix: string = '', returnSnippetString: boolean, needComment: boolean) {
    let params = sVpars.parameters;

    if (params.length === 0) {
        return;
    }

    const maxNameLength = Math.max(...params.map(p => p.name.length));
    const maxInitLength = Math.max(...params.map(p => p.defaultValue.length));

    content.appendText('#(\n');

    // .NAME  ( INIT  ),
    for (let i = 0; i < params.length; ++i) {
        const param = params[i];
        const paddingName = param.name + ' '.repeat(maxNameLength - param.name.length + 1);
        content.appendText(prefix + getIndentString() + '.' + paddingName + getIndentString() + '(');
        if (returnSnippetString) {
            content.appendPlaceholder(param.defaultValue);
        } else {
            content.appendText(param.defaultValue);
        }
        content.appendText(' '.repeat(maxInitLength - param.defaultValue.length) + ')');
        if (i < params.length - 1) {
            content.appendText(',');
        }
        content.appendText('\n');
    }
    content.appendText(prefix + ') ');
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
    for (let i = 0; i < params.length; ++i) {
        const param = params[i];
        const paddingName = param.name + ' '.repeat(maxNameLength - param.name.length + 1);
        content.appendText(prefix + getIndentString() + '.' + paddingName + getIndentString() + '(');
        if (returnSnippetString) {
            content.appendPlaceholder(param.init);
        } else {
            content.appendText(param.init);
        }
        content.appendText(' '.repeat(maxInitLength - param.init.length) + ')');
        if (i < params.length - 1) {
            content.appendText(',');
        }
        content.appendText('\n');
    }
    content.appendText(prefix + ') ');
}

/**
 * @description vhdl模式下对端口信息生成要例化的内容
 * @param ports 端口信息列表
 */
function vhdlPort(ports: HdlModulePort[]): string {
    let nmax = getlmax(ports, 'name');

    // NAME => NAME,
    let portStr = `\t-- ports\n`;
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
        placeHolder: t('info.command.instantiation.pick-title')
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

function instanceByLangID(langID: HdlLangID, module: HdlModule): string {
    switch (langID) {
        case HdlLangID.Verilog: return instanceVlogCode(module);
        case HdlLangID.Vhdl: return instanceVhdlCode(module);
        // TODO : add support for svlog
        case HdlLangID.SystemVerilog: return instanceVlogCode(module);
        default: return '';
    }
}

async function instantiation() {
    const editor = vscode.window.activeTextEditor;
    if (editor === undefined) {
        return;
    }
    const file = hdlPath.toSlash(editor.document.fileName);
    const langID = hdlFile.getLanguageId(file);

    const module = await selectModuleFromAll();
    if (module) {
        const code = instanceByLangID(langID, module);
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
