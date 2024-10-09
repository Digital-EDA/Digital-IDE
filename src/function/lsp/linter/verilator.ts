import * as vscode from "vscode";
import * as fs from 'fs';

import { LspOutput, ReportType, opeParam } from "../../../global";
import { hdlFile, hdlPath } from "../../../hdlFs";
import { easyExec } from "../../../global/util";
import { BaseLinter } from "./base";
import { HdlLangID } from "../../../global/enum";

type Path = string;

class VerilatorLinter implements BaseLinter {
    diagnostic: vscode.DiagnosticCollection;
    executableFileMap: Map<HdlLangID, string | undefined> = new Map<HdlLangID, string>();
    executableInvokeNameMap: Map<HdlLangID, string | undefined> = new Map<HdlLangID, string>();
    linterArgsMap: Map<HdlLangID, string[]> = new Map<HdlLangID, string[]>();

    constructor() {
        this.diagnostic = vscode.languages.createDiagnosticCollection();
        
        // configure map for executable file name
        this.executableFileMap.set(HdlLangID.Verilog, 'verilator');
        this.executableFileMap.set(HdlLangID.SystemVerilog, 'verilator');
        this.executableFileMap.set(HdlLangID.Unknown, undefined);

        // configure map for argruments when lintering
        this.linterArgsMap.set(HdlLangID.Verilog, ['--lint-only', '-Wall', '-bbox-sys', '--bbox-unsup', '-DGLBL']);
        this.linterArgsMap.set(HdlLangID.SystemVerilog, ['--lint-only', '-sv', '-Wall', '-bbox-sys', '--bbox-unsup', '-DGLBL']);
        this.linterArgsMap.set(HdlLangID.Unknown, []);
    }

        
    async lint(document: vscode.TextDocument) {
        const filePath = hdlPath.toSlash(document.fileName);
        const langID = hdlFile.getLanguageId(filePath);

        // acquire install path
        const linterArgs = this.linterArgsMap.get(langID);
        
        if (linterArgs === undefined) {
            return;
        }

        const args = [filePath, ...linterArgs];
        const executor = this.executableInvokeNameMap.get(langID);
        if (executor !== undefined) {
            const { stderr } = await easyExec(executor, args);
            if (stderr.length > 0) {
                const diagnostics = this.provideDiagnostics(document, stderr);
                this.diagnostic.set(document.uri, diagnostics);
            }
        } else {
            LspOutput.report('verilator linter is not available, please check prj.verilator.install.path in your setting', ReportType.Error, true);
        }
    }

    async remove(uri: vscode.Uri) {
        this.diagnostic.delete(uri);
    }

    /**
     * @param document
     * @param stdout stdout from xvlog
     * @returns { vscode.Diagnostic[] } linter info
     */
    private provideDiagnostics(document: vscode.TextDocument, stderr: string): vscode.Diagnostic[] {
        const diagnostics = [];
        for (let line of stderr.split(/\r?\n/g)) {
            if (!line.startsWith('%')) {
                continue;
            } else {
                line = line.substring(1);
            }
    
            const tokens = line.split(':');
            if (tokens.length < 3) {
                continue;
            }
            const header = tokens[0].toLowerCase();
            const fileName = tokens[1];
            const lineNo = parseInt(tokens[2]) - 1;
            const characterNo = parseInt(tokens[3]) - 1;
            const syntaxInfo = tokens[4];

            if (header.startsWith('warning')) {
                const range = this.makeCorrectRange(document, lineNo, characterNo);
                const diag = new vscode.Diagnostic(range, syntaxInfo, vscode.DiagnosticSeverity.Warning);
                diagnostics.push(diag);
            } else if (header.startsWith('error')) {
                const range = this.makeCorrectRange(document, lineNo, characterNo);
                const diag = new vscode.Diagnostic(range, syntaxInfo, vscode.DiagnosticSeverity.Error);
                diagnostics.push(diag);
            }
        }
        return diagnostics;
    }

    private makeCorrectRange(document: vscode.TextDocument, line: number, character: number): vscode.Range {
        const startPosition = new vscode.Position(line, character);
        const wordRange = document.getWordRangeAtPosition(startPosition, /[`_0-9a-zA-Z]+/);
        if (wordRange) {
            return wordRange;
        } else {
            return new vscode.Range(startPosition, startPosition);
        }
    }

    public getExecutableFilePath(langID: HdlLangID): string | Path | undefined {
        // verilator install path stored in prj.verilator.install.path
        const verilatorConfig = vscode.workspace.getConfiguration('digital-ide.prj.verilator');
        const verilatorInstallPath = verilatorConfig.get('install.path', '');
        const executorName = this.executableFileMap.get(langID);
        if (executorName === undefined) {
            return undefined;
        }
        
        // e.g. vlog.exe in windows, vlog in linux
        const fullExecutorName = opeParam.os === 'win32' ? executorName + '.exe' : executorName;
        
        if (verilatorInstallPath.trim() === '' || !fs.existsSync(verilatorInstallPath)) {
            LspOutput.report(`User's verilator Install Path ${verilatorInstallPath}, which is invalid. Use ${executorName} in default.`, ReportType.Warn);
            LspOutput.report('If you have doubts, check prj.verilator.install.path in setting', ReportType.Warn);
            return executorName;
        } else {
            LspOutput.report(`User's verilator Install Path ${verilatorInstallPath}, which is invalid`);
            
            const executorPath = hdlPath.join(
                hdlPath.toSlash(verilatorInstallPath),
                fullExecutorName
            );
            // prevent path like C://stupid name/xxx/xxx/bin
            // blank space
            const safeExecutorPath = '"' + executorPath + '"';
            return safeExecutorPath;
        }
    }


    public async setExecutableFilePath(executorPath: string | Path | undefined, langID: HdlLangID): Promise<boolean> {
        if (executorPath === undefined) {
            return false;
        }
        const { stderr } = await easyExec(executorPath, []);
        if (stderr.length === 0) {
            this.executableInvokeNameMap.set(langID, executorPath);
            LspOutput.report(`success to verify ${executorPath}, linter from verilator is ready to go!`, ReportType.Launch);
            return true;
        } else {
            this.executableInvokeNameMap.set(langID, undefined);
            console.log(stderr);
            
            LspOutput.report(`Fail to execute ${executorPath}! Reason: ${stderr}`, ReportType.Error, true);
            
            return false;
        }
    }

    public async initialise(langID: HdlLangID): Promise<boolean> {
        const executorPath = this.getExecutableFilePath(langID);
        return this.setExecutableFilePath(executorPath, langID);
    }
}

const verilatorLinter = new VerilatorLinter();

export {
    verilatorLinter,
    VerilatorLinter
};
