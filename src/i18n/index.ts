import * as vscode from 'vscode';

const defaultBundle: Record<string, string> = {}

export function t(message: string, ...args: string[]): string {
    if (vscode.l10n.bundle === undefined) {
        let translateMessage = defaultBundle[message] || message;
        for (let i = 0; i < args.length; ++ i) {
            translateMessage.replace(`{${i}}`, args[i]);
        }
        return translateMessage;
    } else {
        return vscode.l10n.t(message, ...args);
    }
}