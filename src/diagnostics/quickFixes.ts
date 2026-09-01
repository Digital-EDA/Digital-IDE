import * as vscode from 'vscode';
import type { LanguageClient } from 'vscode-languageclient/node';

const configurationSection = 'digital-ide.function.lsp.diagnostics';
const overridesSetting = 'overrides';
const diagnosticSource = 'Digital-IDE';
const disableDiagnosticCommand = 'digital-ide.diagnostics.disable';
const fullOverridesSetting = `${configurationSection}.${overridesSetting}`;

type DiagnosticOverrides = Record<string, unknown>;

const latestDiagnostics = new Map<
    string,
    { uri: vscode.Uri; diagnostics: readonly vscode.Diagnostic[] }
>();

function diagnosticCode(diagnostic: vscode.Diagnostic): string | undefined {
    if (typeof diagnostic.code === 'string') {
        return diagnostic.code;
    }
    if (typeof diagnostic.code === 'number') {
        return String(diagnostic.code);
    }
    return undefined;
}

function configuredOverrides(uri: vscode.Uri): DiagnosticOverrides {
    const value = vscode.workspace
        .getConfiguration(configurationSection, uri)
        .get<unknown>(overridesSetting, {});
    if (!value || typeof value !== 'object' || Array.isArray(value)) {
        return {};
    }
    return value as DiagnosticOverrides;
}

export function applyDiagnosticOverrides(
    uri: vscode.Uri,
    diagnostics: readonly vscode.Diagnostic[],
): vscode.Diagnostic[] {
    const overrides = configuredOverrides(uri);
    return diagnostics.filter(diagnostic => {
        if (diagnostic.source !== diagnosticSource) {
            return true;
        }
        const code = diagnosticCode(diagnostic);
        return code === undefined || overrides[code] !== 'off';
    });
}

export function handleDiagnosticPublication(
    uri: vscode.Uri,
    diagnostics: readonly vscode.Diagnostic[],
): vscode.Diagnostic[] {
    latestDiagnostics.set(uri.toString(), { uri, diagnostics: [...diagnostics] });
    return applyDiagnosticOverrides(uri, diagnostics);
}

function isErrorOrWarning(diagnostic: vscode.Diagnostic): boolean {
    return diagnostic.severity === vscode.DiagnosticSeverity.Error
        || diagnostic.severity === vscode.DiagnosticSeverity.Warning;
}

function refreshDiagnostics(client: LanguageClient): void {
    const collection = client.diagnostics;
    if (!collection) {
        return;
    }
    const filtered = Array.from(latestDiagnostics.values(), ({ uri, diagnostics }) => [
        uri,
        applyDiagnosticOverrides(uri, diagnostics),
    ] as [vscode.Uri, readonly vscode.Diagnostic[]]);
    collection.set(filtered);
}

async function disableDiagnostic(
    client: LanguageClient,
    uri: vscode.Uri,
    code: string,
): Promise<void> {
    if (!vscode.workspace.getWorkspaceFolder(uri)) {
        void vscode.window.showErrorMessage(
            'Digital-IDE cannot disable a diagnostic outside a workspace folder.',
        );
        return;
    }

    const configuration = vscode.workspace.getConfiguration(configurationSection, uri);
    const overrides = configuredOverrides(uri);
    await configuration.update(
        overridesSetting,
        { ...overrides, [code]: 'off' },
        vscode.ConfigurationTarget.WorkspaceFolder,
    );
    refreshDiagnostics(client);
}

export function registerDiagnosticQuickFixes(
    context: vscode.ExtensionContext,
    client: LanguageClient,
): void {
    const selector: vscode.DocumentSelector = [
        { scheme: 'file', language: 'systemverilog' },
        { scheme: 'file', language: 'verilog' },
        { scheme: 'file', language: 'vhdl' },
    ];
    const provider: vscode.CodeActionProvider = {
        provideCodeActions(_document, _range, actionContext) {
            return actionContext.diagnostics.flatMap(diagnostic => {
                const code = diagnosticCode(diagnostic);
                if (diagnostic.source !== diagnosticSource
                    || !isErrorOrWarning(diagnostic)
                    || code === undefined) {
                    return [];
                }
                const action = new vscode.CodeAction(
                    'Disable this error',
                    vscode.CodeActionKind.QuickFix,
                );
                action.diagnostics = [diagnostic];
                action.command = {
                    command: disableDiagnosticCommand,
                    title: action.title,
                    arguments: [_document.uri, code],
                };
                return [action];
            });
        },
    };

    context.subscriptions.push(
        vscode.languages.registerCodeActionsProvider(selector, provider, {
            providedCodeActionKinds: [vscode.CodeActionKind.QuickFix],
        }),
        vscode.commands.registerCommand(
            disableDiagnosticCommand,
            (uri: vscode.Uri, code: string) => disableDiagnostic(client, uri, code),
        ),
        vscode.workspace.onDidChangeConfiguration(event => {
            if (event.affectsConfiguration(fullOverridesSetting)) {
                refreshDiagnostics(client);
            }
        }),
    );
}
