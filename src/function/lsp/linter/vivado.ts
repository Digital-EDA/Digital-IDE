import * as vscode from "vscode";
import * as fs from 'fs';
import * as childProcess from 'child_process';

import { LspOutput, ReportType, opeParam } from "../../../global";
import { Path } from "../../../../resources/hdlParser";
import { hdlFile, hdlPath } from "../../../hdlFs";
import { easyExec } from "../../../global/util";
import { BaseLinter } from "./base";
import { HdlLangID } from "../../../global/enum";

class VivadoLinter implements BaseLinter {
    diagnostic: vscode.DiagnosticCollection;
    executableFileMap: Map<HdlLangID, string | undefined> = new Map<HdlLangID, string>();
    executableInvokeNameMap: Map<HdlLangID, string | undefined> = new Map<HdlLangID, string>();
    linterArgsMap: Map<HdlLangID, string[]> = new Map<HdlLangID, string[]>();

    constructor() {
        this.diagnostic = vscode.languages.createDiagnosticCollection();
        
        // configure map for executable file name
        this.executableFileMap.set(HdlLangID.Verilog, 'xvlog');
        this.executableFileMap.set(HdlLangID.Vhdl, 'xvhdl');
        this.executableFileMap.set(HdlLangID.SystemVerilog, 'xvlog');
        this.executableFileMap.set(HdlLangID.Unknown, undefined);

        // configure map for argruments when lintering
        this.linterArgsMap.set(HdlLangID.Verilog, ['--nolog']);
        this.linterArgsMap.set(HdlLangID.Vhdl, ['--nolog']);
        this.linterArgsMap.set(HdlLangID.SystemVerilog, ['--sv', '--nolog']);
        this.linterArgsMap.set(HdlLangID.Unknown, []);

        const executablePath = this.selectExecutableFilePath();
        this.setExecutablePath(executablePath);
    }
    
    async lint(document: vscode.TextDocument) {
        const filePath = document.fileName;

        // acquire install path
        const args = [hdlPath.toSlash(filePath), ...this.linterArgs];
        const executor = this.xvlogExecutablePath;
        if (executor !== undefined) {
            const { stdout, stderr } = await easyExec(executor, args);
            if (stdout.length > 0) {
                const diagnostics = this.provideDiagnostics(document, stdout);
                this.diagnostic.set(document.uri, diagnostics);
            }
        } else {
            LspOutput.report('linter is not available, please check prj.vivado.install.path in your setting', ReportType.Error);
        }
    }

    /**
     * @param document
     * @param stdout stdout from xvlog
     * @returns { vscode.Diagnostic[] } linter info
     */
    private provideDiagnostics(document: vscode.TextDocument, stdout: string): vscode.Diagnostic[] {
        const diagnostics = [];
        for (const line of stdout.split('\n')) {
            const tokens = line.split(/:?\s*(?:\[|\])\s*/);
            const headerInfo = tokens[0];
            // const standardInfo = tokens[1];
            const syntaxInfo = tokens[2];
            const parsedPath = tokens[3];
            if (headerInfo === 'ERROR') {
                const errorInfos = parsedPath.split(':');
                const errorLine = parseInt(errorInfos[errorInfos.length - 1]);
                const range = this.makeCorrectRange(document, errorLine);
                const diag = new vscode.Diagnostic(range, syntaxInfo, vscode.DiagnosticSeverity.Error);
                diagnostics.push(diag);
            }
        }
        return diagnostics;
    }

    private makeCorrectRange(document: vscode.TextDocument, line: number): vscode.Range {
        const startPosition = new vscode.Position(line, 0);
        const wordRange = document.getWordRangeAtPosition(startPosition, /[`_0-9a-zA-Z]+/);
        if (wordRange) {
            return wordRange;
        } else {
            return new vscode.Range(startPosition, startPosition);
        }
    }

    private selectExecutableFilePath(langID: HdlLangID): string | Path {
        // vivado install path stored in prj.vivado.install.path
        const vivadoConfig = vscode.workspace.getConfiguration('prj.vivado');
        const vivadoInstallPath = vivadoConfig.get('install.path', '');
        if (vivadoInstallPath.trim() === '' || !fs.existsSync(vivadoInstallPath)) {
            LspOutput.report(`User's Vivado Install Path ${vivadoInstallPath}, which is invalid. Use xvlog in default.`, ReportType.Warn);
            LspOutput.report('If you have doubts, check prj.vivado.install.path in setting', ReportType.Warn);
            return 'xvlog';
        } else {
            LspOutput.report(`User's Vivado Install Path ${vivadoInstallPath}, which is invalid`);
            
            const xvlogPath = hdlPath.join(
                hdlPath.toSlash(vivadoInstallPath),
                // this.selectExecutableBasicName(langID)
            );
            // prevent path like C://stupid name/xxx/xxx/bin
            // blank space
            const safeXvlogPath = '"' + xvlogPath + '"';
            return safeXvlogPath;
        }
    }

    private selectExecutableBasicName(langID: HdlLangID): string | undefined {
        const basicName = this.executableFileMap.get(langID);
        if (!basicName) {
            return basicName;
        }
        if (opeParam.os === 'win32') {
            // e.g. xvlog.bat
            return basicName + '.bat';
        } else {
            // e.g. xvlog
            return basicName;
        }
    }

    public async setExecutablePath(executorPath: string | Path, langID: HdlLangID): Promise<boolean> {
        const { stdout, stderr } = await easyExec(executorPath, []);
        if (stderr.length === 0) {
            this.executableInvokeNameMap.set(langID, undefined);
            LspOutput.report(`fail to execute ${executorPath}! Reason: ${stderr}`, ReportType.Error);
            return false;
        } else {
            this.executableInvokeNameMap.set(langID, executorPath);
            LspOutput.report(`success to verify ${executorPath}, linter from vivado is ready to go!`, ReportType.Launch);
            return true;
        }
    }
}

class XvhdlLinter implements BaseLinter {
    diagnostic: vscode.DiagnosticCollection;
    xvhdlExecutablePath: string | undefined;
    linterArgs: string[] = ['--nolog'];

    constructor() {
        this.diagnostic = vscode.languages.createDiagnosticCollection();
        const executablePath = this.selectExecutableFilePath();
        this.setExecutablePath(executablePath);
    }

    async lint(document: vscode.TextDocument): Promise<void> {
        const filePath = document.fileName;

        // acquire install path
        const args = [hdlPath.toSlash(filePath), ...this.linterArgs];
        const executor = this.xvhdlExecutablePath;
        if (executor !== undefined) {
            const { stdout, stderr } = await easyExec(executor, args);
            if (stdout.length > 0) {
                const diagnostics = this.provideDiagnostics(document, stdout);
                this.diagnostic.set(document.uri, diagnostics);
            }
        } else {
            LspOutput.report('linter is not available, please check prj.vivado.install.path in your setting', ReportType.Error);
        }
    }

    
    /**
     * @param document
     * @param stdout stdout from xvlog
     * @returns { vscode.Diagnostic[] } linter info
     */
    private provideDiagnostics(document: vscode.TextDocument, stdout: string): vscode.Diagnostic[] {
        const diagnostics = [];
        for (const line of stdout.split('\n')) {
            const tokens = line.split(/:?\s*(?:\[|\])\s*/);
            const headerInfo = tokens[0];
            // const standardInfo = tokens[1];
            const syntaxInfo = tokens[2];
            const parsedPath = tokens[3];
            if (headerInfo === 'ERROR') {
                const errorInfos = parsedPath.split(':');
                const errorLine = parseInt(errorInfos[errorInfos.length - 1]);
                const range = this.makeCorrectRange(document, errorLine);
                const diag = new vscode.Diagnostic(range, syntaxInfo, vscode.DiagnosticSeverity.Error);
                diagnostics.push(diag);
            }
        }
        return diagnostics;
    }

    private makeCorrectRange(document: vscode.TextDocument, line: number): vscode.Range {
        const startPosition = new vscode.Position(line, 0);
        const wordRange = document.getWordRangeAtPosition(startPosition, /[`_0-9a-zA-Z]+/);
        if (wordRange) {
            return wordRange;
        } else {
            return new vscode.Range(startPosition, startPosition);
        }
    }

    private selectExecutableFilePath(): string | Path {
        // vivado install path stored in prj.vivado.install.path
        const vivadoConfig = vscode.workspace.getConfiguration('prj.vivado');
        const vivadoInstallPath = vivadoConfig.get('install.path', '');
        if (vivadoInstallPath.trim() === '' || !fs.existsSync(vivadoInstallPath)) {
            LspOutput.report(`User's Vivado Install Path ${vivadoInstallPath}, which is invalid. Use xvhdl in default.`, ReportType.Warn);
            LspOutput.report('If you have doubts, check prj.vivado.install.path in setting', ReportType.Warn);
            return 'xvhdl';
        } else {
            LspOutput.report(`User's Vivado Install Path ${vivadoInstallPath}, which is invalid`);
            
            const xvhdlPath = hdlPath.join(
                hdlPath.toSlash(vivadoInstallPath),
                this.selectXvhdlFilename()
            );
            // prevent path like C://stupid name/xxx/xxx/bin
            // blank space
            const safeXvhdlPath = '"' + xvhdlPath + '"';
            return safeXvhdlPath;
        }
    }

    private selectXvhdlFilename(): string {
        if (opeParam.os === 'win32') {
            return 'xvhdl.bat';
        } else {
            return 'xvhdl';
        }
    }

    public async setExecutablePath(path: string | Path): Promise<boolean> {
        const { stdout, stderr } = await easyExec(path, []);
        if (stderr.length === 0) {
            this.xvhdlExecutablePath = undefined;
            LspOutput.report(`fail to execute ${path}! Reason: ${stderr}`, ReportType.Error);
            return false;
        } else {
            this.xvhdlExecutablePath = path;
            LspOutput.report(`success to verify ${path}, linter from vivado is ready to go!`, ReportType.Launch);
            return true;
        }
    }
}

export {
    VivadoLinter,
    XvhdlLinter
};