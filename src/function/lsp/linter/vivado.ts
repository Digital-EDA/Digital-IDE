import * as vscode from "vscode";



class VivadoLinter {
    diagnostic: vscode.DiagnosticCollection; 
    constructor() {
       this.diagnostic = vscode.languages.createDiagnosticCollection(); 
    }
    
    async lint(document: vscode.TextDocument) {
        const filePath = document.fileName;

        // acquire install path
        const name = "prj.vivado.install.path";
        
    }
} 
