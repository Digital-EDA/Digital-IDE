import * as vscode from 'vscode';

export function activate(context: vscode.ExtensionContext) {
	console.log('Congratulations, your extension "digital-ide" is now active!');
	let disposable = vscode.commands.registerCommand('digital-ide.helloWorld', () => {
		vscode.window.showInformationMessage('Hello World from digital-ide!');
	});

	context.subscriptions.push(disposable);
}

export function deactivate() {}