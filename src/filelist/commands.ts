import * as path from 'path';
import * as vscode from 'vscode';
import { LanguageClient } from 'vscode-languageclient/node';
import { MainOutput, ReportType } from '../global/outputs';
import { normalizeWindowsPath } from '../utils/paths';

export type FilelistAction = 'import' | 'export';

export interface FilelistCommandOptions {
    workspaceUri?: vscode.Uri | string;
    path?: vscode.Uri | string;
    file?: unknown;
    rootPath?: vscode.Uri | string;
    moduleName?: string;
    kind?: 'src' | 'sim';
    scope?: 'src' | 'sim' | 'all';
    apply?: boolean;
    relativePaths?: boolean;
    silent?: boolean;
}

export interface FilelistResponse {
    success: boolean;
    action: FilelistAction;
    message: string;
    workspace: string;
    path: string;
    applied: boolean;
    workspaceEpoch: number;
    configGeneration: number;
    files: string[];
    includeDirs: string[];
    defines: Record<string, string | null>;
    nestedFilelists: string[];
    ignored: string[];
    changes: string[];
}

export function registerFilelistCommands(
    context: vscode.ExtensionContext,
    client: LanguageClient,
): void {
    context.subscriptions.push(
        vscode.commands.registerCommand(
            'digital-ide.tool.import-filelist',
            (options?: FilelistCommandOptions) => runFilelist(client, 'import', options),
        ),
        vscode.commands.registerCommand(
            'digital-ide.tool.export-filelist',
            (options?: FilelistCommandOptions) => runFilelist(client, 'export', options),
        ),
    );
}

async function runFilelist(
    client: LanguageClient,
    action: FilelistAction,
    options?: FilelistCommandOptions,
): Promise<FilelistResponse> {
    const treeNode = architectureTreeNode(options?.file) ?? architectureTreeNode(options);
    const workspaceUri = resolveWorkspaceUri(options?.workspaceUri);
    if (!workspaceUri) {
        throw new Error('Filelist commands require an open workspace folder');
    }
    const fileUri = await resolveFilelistUri(
        action,
        workspaceUri,
        treeNode ? undefined : options?.path,
    );
    if (!fileUri) {
        throw new Error(`Filelist ${action} was cancelled`);
    }
    const response = await client.sendRequest<FilelistResponse>('digital/filelist', {
        action,
        workspaceUri: workspaceUri.toString(),
        path: normalizeWindowsPath(fileUri.fsPath),
        kind: options?.kind ?? 'src',
        scope: options?.scope ?? 'all',
        rootPath: normalizeOptionalPath(treeNode?.path ?? uriPath(options?.rootPath)),
        moduleName: treeNode?.name ?? options?.moduleName,
        apply: action === 'export' ? true : options?.apply ?? true,
        relativePaths: options?.relativePaths ?? true,
    });
    for (const change of response.changes) {
        MainOutput.report(change, { level: ReportType.PrintOuput });
    }
    for (const ignored of response.ignored) {
        MainOutput.report(ignored, { level: ReportType.Warn });
    }
    if (!response.success) {
        if (!options?.silent) {
            void vscode.window.showErrorMessage(response.message);
        }
        throw new Error(response.message);
    }
    if (!options?.silent) {
        void vscode.window.showInformationMessage(response.message);
    }
    return response;
}

function architectureTreeNode(value: unknown): { path: string; name: string } | undefined {
    if (!value || typeof value !== 'object') {
        return undefined;
    }
    const candidate = value as { treeView?: unknown; path?: unknown; name?: unknown };
    return candidate.treeView === 'architecture'
        && typeof candidate.path === 'string'
        && typeof candidate.name === 'string'
        ? { path: candidate.path, name: candidate.name }
        : undefined;
}

function uriPath(value: vscode.Uri | string | undefined): string | undefined {
    if (value instanceof vscode.Uri) {
        return normalizeWindowsPath(value.fsPath);
    }
    if (typeof value === 'string') {
        return normalizeWindowsPath(
            value.startsWith('file:') ? vscode.Uri.parse(value).fsPath : value,
        );
    }
    return undefined;
}

function normalizeOptionalPath(value: string | undefined): string | undefined {
    return value === undefined ? undefined : normalizeWindowsPath(value);
}

async function resolveFilelistUri(
    action: FilelistAction,
    workspaceUri: vscode.Uri,
    requested?: vscode.Uri | string,
): Promise<vscode.Uri | undefined> {
    if (requested instanceof vscode.Uri) {
        return requested;
    }
    if (typeof requested === 'string') {
        return vscode.Uri.file(normalizeWindowsPath(path.isAbsolute(requested)
            ? requested
            : path.join(normalizeWindowsPath(workspaceUri.fsPath), requested)));
    }
    if (action === 'import') {
        return (await vscode.window.showOpenDialog({
            defaultUri: workspaceUri,
            canSelectFiles: true,
            canSelectFolders: false,
            canSelectMany: false,
            filters: { filelist: ['f', 'fl', 'filelist'] },
            title: 'Import Filelist',
        }))?.[0];
    }
    return vscode.window.showSaveDialog({
        defaultUri: vscode.Uri.file(path.join(
            normalizeWindowsPath(workspaceUri.fsPath),
            'filelist.f',
        )),
        filters: { filelist: ['f'] },
        title: 'Export Filelist',
    });
}

function resolveWorkspaceUri(requested?: vscode.Uri | string): vscode.Uri | undefined {
    if (requested instanceof vscode.Uri) {
        return requested;
    }
    if (typeof requested === 'string') {
        return vscode.Uri.parse(requested);
    }
    const active = vscode.window.activeTextEditor?.document.uri;
    return (active && vscode.workspace.getWorkspaceFolder(active)?.uri)
        ?? vscode.workspace.workspaceFolders?.[0]?.uri;
}
