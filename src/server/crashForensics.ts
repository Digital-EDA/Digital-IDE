import * as childProcess from 'child_process';
import * as crypto from 'crypto';
import * as fs from 'fs';
import * as os from 'os';
import * as path from 'path';
import * as vscode from 'vscode';
import type { ServerOptions } from 'vscode-languageclient/node';
import { MainOutput, ReportType } from '../global/outputs';

const evidenceSchema = 'digital-ide.server-crash-evidence.v1';
const accessViolation = 0xc0000005;
const hdlGlob = '**/*.{v,V,vh,vl,sv,svh,SV,vhd,vhdl,vho,vht}';
const hdlExclude = '**/{.git,node_modules,target,out,dist,.vscode-test}/**';
const maxManifestFiles = 20000;
const maxHashedFileBytes = 64 * 1024 * 1024;

interface CrashSession {
    readonly directory: string;
    readonly startedAt: string;
    readonly stderr: fs.WriteStream;
    readonly activity: fs.WriteStream;
    readonly serverPath: string;
    readonly serverCwd: string;
    processId?: number;
    monitor?: childProcess.ChildProcess;
    monitorExit?: Promise<void>;
}

interface CrashForensicsOptions {
    readonly serverPath: string;
    readonly serverCwd: string;
    readonly serverEnv: NodeJS.ProcessEnv;
    readonly initializationOptions: Record<string, unknown>;
}

interface FileEvidence {
    readonly workspace: string;
    readonly path: string;
    readonly bytes?: number;
    readonly modifiedMs?: number;
    readonly sha256?: string;
    readonly hashStatus: 'hashed' | 'too-large' | 'unreadable';
}

export function unsignedWindowsExitCode(code: number | null): number | null {
    return code === null ? null : code >>> 0;
}

export function windowsExitCodeHex(code: number | null): string | null {
    const unsigned = unsignedWindowsExitCode(code);
    return unsigned === null ? null : `0x${unsigned.toString(16).padStart(8, '0').toUpperCase()}`;
}

export function isWindowsAccessViolation(code: number | null): boolean {
    return unsignedWindowsExitCode(code) === accessViolation;
}

export class ServerCrashForensics implements vscode.Disposable {
    private readonly evidenceRoot: string;
    private readonly disposables: vscode.Disposable[] = [];
    private readonly activeSessions = new Set<CrashSession>();
    private expectedShutdown = false;
    private latestEvidence: string | undefined;

    public constructor(
        private readonly context: vscode.ExtensionContext,
        private readonly options: CrashForensicsOptions,
    ) {
        this.evidenceRoot = path.join(context.globalStorageUri.fsPath, 'server-crash-evidence');
        this.registerCommands();
        this.registerActivitySources();
    }

    public serverOptions(): ServerOptions {
        return async () => this.startServer();
    }

    public markExpectedShutdown(): void {
        this.expectedShutdown = true;
    }

    public dispose(): void {
        this.markExpectedShutdown();
        for (const disposable of this.disposables) {
            disposable.dispose();
        }
        for (const session of this.activeSessions) {
            session.activity.end();
            session.stderr.end();
            session.monitor?.kill();
        }
        this.activeSessions.clear();
    }

    private async startServer(): Promise<childProcess.ChildProcess> {
        this.expectedShutdown = false;
        const session = await this.createSession();
        const server = childProcess.spawn(this.options.serverPath, [], {
            cwd: this.options.serverCwd,
            env: this.options.serverEnv,
            windowsHide: true,
            stdio: ['pipe', 'pipe', 'pipe'],
        });
        if (server.pid === undefined) {
            session.stderr.end();
            session.activity.end();
            throw new Error('Digital Server started without a process id');
        }

        session.processId = server.pid;
        this.activeSessions.add(session);
        this.recordActivity('server-start', {
            processId: server.pid,
            serverPath: this.options.serverPath,
            serverCwd: this.options.serverCwd,
        }, session);
        server.stderr?.on('data', chunk => session.stderr.write(chunk));
        server.once('error', error => {
            this.recordActivity('server-process-error', { error: String(error) }, session);
        });
        server.once('close', (code, signal) => {
            void this.finalizeSession(session, code, signal).catch(error => {
                MainOutput.report(`Failed to finalize server crash evidence: ${String(error)}`, {
                    level: ReportType.Error,
                });
            });
        });

        if (process.platform === 'win32' && this.captureEnabled()) {
            await this.attachWindowsMonitor(session);
        }
        return server;
    }

    private async createSession(): Promise<CrashSession> {
        await fs.promises.mkdir(this.evidenceRoot, { recursive: true });
        const startedAt = new Date().toISOString();
        const timestamp = startedAt.replace(/[:.]/g, '-');
        const suffix = crypto.randomBytes(4).toString('hex');
        const directory = path.join(this.evidenceRoot, `${timestamp}-${suffix}`);
        await fs.promises.mkdir(directory, { recursive: true });
        const session: CrashSession = {
            directory,
            startedAt,
            stderr: fs.createWriteStream(path.join(directory, 'server.stderr.log'), { flags: 'a' }),
            activity: fs.createWriteStream(path.join(directory, 'activity.jsonl'), { flags: 'a' }),
            serverPath: this.options.serverPath,
            serverCwd: this.options.serverCwd,
        };
        const server = await this.serverEvidence();
        this.reportServerHashes(server);
        await this.writeJson(path.join(directory, 'manifest.json'), {
            schema: evidenceSchema,
            status: 'running',
            startedAt,
            extension: {
                id: this.context.extension.id,
                version: String(this.context.extension.packageJSON.version ?? 'unknown'),
                mode: vscode.ExtensionMode[this.context.extensionMode],
            },
            host: this.hostEvidence(),
            server,
            workspaceFolders: this.workspaceFolders(),
            initializationOptions: this.options.initializationOptions,
            openDocuments: this.openDocumentEvidence(),
        });
        return session;
    }

    private async attachWindowsMonitor(session: CrashSession): Promise<void> {
        const processId = session.processId;
        if (processId === undefined) {
            return;
        }
        const monitorScript = this.context.asAbsolutePath(
            path.join('resources', 'crash', 'windows-server-monitor.ps1'),
        );
        if (!fs.existsSync(monitorScript)) {
            this.recordActivity('monitor-unavailable', { monitorScript }, session);
            return;
        }
        const dumpPath = path.join(session.directory, 'digital-server.dmp');
        const eventPath = path.join(session.directory, 'crash-event.json');
        const dumpType = this.fullMemoryDumpEnabled() ? '14375' : '6181';
        const powershell = this.windowsPowerShellPath();
        const monitor = childProcess.spawn(powershell, [
            '-NoLogo',
            '-NoProfile',
            '-NonInteractive',
            '-ExecutionPolicy',
            'Bypass',
            '-File',
            monitorScript,
            '-TargetProcessId',
            String(processId),
            '-DumpPath',
            dumpPath,
            '-EventPath',
            eventPath,
            '-DumpType',
            dumpType,
        ], {
            windowsHide: true,
            stdio: ['ignore', 'pipe', 'pipe'],
        });
        session.monitor = monitor;
        const monitorLog = fs.createWriteStream(
            path.join(session.directory, 'monitor.log'),
            { flags: 'a' },
        );
        monitor.stdout?.on('data', chunk => monitorLog.write(chunk));
        monitor.stderr?.on('data', chunk => monitorLog.write(chunk));
        session.monitorExit = new Promise(resolve => {
            monitor.once('close', (code, signal) => {
                monitorLog.end();
                if (!session.activity.writableEnded) {
                    this.recordActivity('monitor-exit', { code, signal }, session);
                }
                resolve();
            });
        });

        try {
            await this.waitForMonitorReady(monitor, 10000);
            this.recordActivity('monitor-attached', { processId, dumpType }, session);
        } catch (error) {
            this.recordActivity('monitor-attach-failed', { error: String(error) }, session);
            MainOutput.report(
                `Digital Server crash monitor could not attach: ${String(error)}`,
                { level: ReportType.Warn },
            );
        }
    }

    private waitForMonitorReady(
        monitor: childProcess.ChildProcess,
        timeoutMs: number,
    ): Promise<void> {
        return new Promise((resolve, reject) => {
            let pending = '';
            let settled = false;
            const finish = (error?: Error) => {
                if (settled) {
                    return;
                }
                settled = true;
                clearTimeout(timer);
                monitor.stdout?.off('data', onData);
                monitor.off('error', onError);
                monitor.off('exit', onExit);
                error ? reject(error) : resolve();
            };
            const onData = (chunk: Buffer | string) => {
                pending += chunk.toString();
                if (pending.includes('DIDE_CRASH_MONITOR_READY')) {
                    finish();
                }
            };
            const onError = (error: Error) => finish(error);
            const onExit = (code: number | null) => {
                finish(new Error(`monitor exited before attaching (code ${String(code)})`));
            };
            const timer = setTimeout(
                () => finish(new Error(`monitor attach timed out after ${timeoutMs} ms`)),
                timeoutMs,
            );
            monitor.stdout?.on('data', onData);
            monitor.once('error', onError);
            monitor.once('exit', onExit);
        });
    }

    private async finalizeSession(
        session: CrashSession,
        code: number | null,
        signal: NodeJS.Signals | null,
    ): Promise<void> {
        this.activeSessions.delete(session);
        await this.endStream(session.stderr);
        this.recordActivity('server-exit', {
            code,
            unsignedCode: unsignedWindowsExitCode(code),
            codeHex: windowsExitCodeHex(code),
            signal,
            expected: this.expectedShutdown,
        }, session);
        if (session.monitorExit) {
            await Promise.race([session.monitorExit, this.delay(5000)]);
        }
        await this.endStream(session.activity);

        const abnormal = !this.expectedShutdown && (code !== 0 || signal !== null);
        if (!abnormal) {
            await fs.promises.rm(session.directory, { recursive: true, force: true });
            return;
        }

        await Promise.all([
            this.writeJson(
                path.join(session.directory, 'workspace-files.json'),
                await this.workspaceFileEvidence(),
            ),
            this.copyServerArtifacts(session),
        ]);
        const crashEvent = await this.readJsonIfPresent(
            path.join(session.directory, 'crash-event.json'),
        );
        await this.writeJson(path.join(session.directory, 'manifest.json'), {
            schema: evidenceSchema,
            status: 'crashed',
            startedAt: session.startedAt,
            finishedAt: new Date().toISOString(),
            processId: session.processId,
            exit: {
                code,
                unsignedCode: unsignedWindowsExitCode(code),
                codeHex: windowsExitCodeHex(code),
                signal,
                accessViolation: isWindowsAccessViolation(code),
            },
            crashEvent,
            extension: {
                id: this.context.extension.id,
                version: String(this.context.extension.packageJSON.version ?? 'unknown'),
                mode: vscode.ExtensionMode[this.context.extensionMode],
            },
            host: this.hostEvidence(),
            server: await this.serverEvidence(),
            workspaceFolders: this.workspaceFolders(),
            initializationOptions: this.options.initializationOptions,
            openDocuments: this.openDocumentEvidence(),
        });
        await this.writeIntegrityManifest(session.directory);
        this.latestEvidence = session.directory;
        await this.pruneEvidence();
        this.notifyCrash(session.directory, code);
    }

    private async copyServerArtifacts(session: CrashSession): Promise<void> {
        const artifactDirectory = path.join(session.directory, 'artifacts');
        await fs.promises.mkdir(artifactDirectory, { recursive: true });
        await fs.promises.copyFile(
            session.serverPath,
            path.join(artifactDirectory, path.basename(session.serverPath)),
        );
        for (const pdbName of ['digital_server.pdb', 'digital-server.pdb']) {
            const pdbPath = path.join(path.dirname(session.serverPath), pdbName);
            if (fs.existsSync(pdbPath)) {
                await fs.promises.copyFile(pdbPath, path.join(artifactDirectory, pdbName));
                break;
            }
        }
    }

    private notifyCrash(directory: string, code: number | null): void {
        const codeText = windowsExitCodeHex(code) ?? String(code);
        const description = isWindowsAccessViolation(code)
            ? `${codeText} (STATUS_ACCESS_VIOLATION)`
            : codeText;
        MainOutput.report(`Digital Server crashed with ${description}. Evidence: ${directory}`, {
            level: ReportType.Error,
        });
        void vscode.window.showErrorMessage(
            `Digital Server crashed with ${description}. Crash evidence was captured.`,
            'Open Evidence',
            'Export ZIP',
        ).then(selection => {
            if (selection === 'Open Evidence') {
                return this.openLatestEvidence();
            }
            if (selection === 'Export ZIP') {
                return this.exportLatestEvidence();
            }
            return undefined;
        });
    }

    private registerCommands(): void {
        this.disposables.push(
            vscode.commands.registerCommand(
                'digital-ide.server.openCrashEvidence',
                () => this.openLatestEvidence(),
            ),
            vscode.commands.registerCommand(
                'digital-ide.server.exportCrashEvidence',
                () => this.exportLatestEvidence(),
            ),
        );
    }

    private registerActivitySources(): void {
        this.disposables.push(
            vscode.workspace.onDidOpenTextDocument(document => {
                this.recordActivity('document-open', this.documentEvidence(document));
            }),
            vscode.workspace.onDidChangeTextDocument(event => {
                this.recordActivity('document-change', {
                    ...this.documentEvidence(event.document),
                    changes: event.contentChanges.map(change => ({
                        range: change.range,
                        rangeLength: change.rangeLength,
                        textBytes: Buffer.byteLength(change.text, 'utf8'),
                        textSha256: this.sha256Text(change.text),
                    })),
                });
            }),
            vscode.workspace.onDidSaveTextDocument(document => {
                this.recordActivity('document-save', this.documentEvidence(document));
            }),
            vscode.window.onDidChangeActiveTextEditor(editor => {
                this.recordActivity('active-editor', editor
                    ? this.documentEvidence(editor.document)
                    : { uri: null });
            }),
        );
    }

    private recordActivity(
        kind: string,
        details: Record<string, unknown>,
        onlySession?: CrashSession,
    ): void {
        const line = `${JSON.stringify({ at: new Date().toISOString(), kind, ...details })}\n`;
        if (onlySession) {
            onlySession.activity.write(line);
            return;
        }
        for (const session of this.activeSessions) {
            session.activity.write(line);
        }
    }

    private documentEvidence(document: vscode.TextDocument): Record<string, unknown> {
        const text = document.getText();
        return {
            uri: document.uri.toString(),
            languageId: document.languageId,
            version: document.version,
            dirty: document.isDirty,
            bytes: Buffer.byteLength(text, 'utf8'),
            sha256: this.sha256Text(text),
        };
    }

    private openDocumentEvidence(): Record<string, unknown>[] {
        return vscode.workspace.textDocuments
            .filter(document => document.uri.scheme === 'file')
            .map(document => this.documentEvidence(document));
    }

    private workspaceFolders(): string[] {
        return (vscode.workspace.workspaceFolders ?? []).map(folder => folder.uri.fsPath);
    }

    private async workspaceFileEvidence(): Promise<Record<string, unknown>> {
        const uris = await vscode.workspace.findFiles(hdlGlob, hdlExclude, maxManifestFiles);
        const files: FileEvidence[] = [];
        for (const uri of uris.sort((left, right) => left.fsPath.localeCompare(right.fsPath))) {
            const workspace = vscode.workspace.getWorkspaceFolder(uri);
            const workspacePath = workspace?.uri.fsPath ?? '';
            const relativePath = workspace
                ? path.relative(workspacePath, uri.fsPath)
                : uri.fsPath;
            try {
                const stat = await fs.promises.stat(uri.fsPath);
                if (stat.size > maxHashedFileBytes) {
                    files.push({
                        workspace: workspacePath,
                        path: relativePath,
                        bytes: stat.size,
                        modifiedMs: stat.mtimeMs,
                        hashStatus: 'too-large',
                    });
                    continue;
                }
                files.push({
                    workspace: workspacePath,
                    path: relativePath,
                    bytes: stat.size,
                    modifiedMs: stat.mtimeMs,
                    sha256: await this.sha256File(uri.fsPath),
                    hashStatus: 'hashed',
                });
            } catch {
                files.push({
                    workspace: workspacePath,
                    path: relativePath,
                    hashStatus: 'unreadable',
                });
            }
        }
        return {
            schema: `${evidenceSchema}.workspace-files`,
            generatedAt: new Date().toISOString(),
            truncated: uris.length >= maxManifestFiles,
            limit: maxManifestFiles,
            files,
        };
    }

    private hostEvidence(): Record<string, unknown> {
        return {
            platform: process.platform,
            architecture: process.arch,
            osType: os.type(),
            osRelease: os.release(),
            osVersion: typeof os.version === 'function' ? os.version() : undefined,
            cpuCount: os.cpus().length,
            cpuModels: Array.from(new Set(os.cpus().map(cpu => cpu.model))),
            totalMemoryBytes: os.totalmem(),
            locale: vscode.env.language,
            remoteName: vscode.env.remoteName,
            appName: vscode.env.appName,
            appHost: vscode.env.appHost,
            appVersion: vscode.version,
            node: process.versions.node,
            electron: process.versions.electron,
        };
    }

    private reportServerHashes(server: Record<string, unknown>): void {
        if (typeof server.sha256 === 'string') {
            MainOutput.report(`Digital Server SHA-256: ${server.sha256}`, {
                level: ReportType.PathCheck,
            });
        }
        const symbols = server.symbols;
        if (symbols && typeof symbols === 'object' && 'sha256' in symbols
            && typeof symbols.sha256 === 'string') {
            MainOutput.report(`Digital Server symbols SHA-256: ${symbols.sha256}`, {
                level: ReportType.PathCheck,
            });
        }
    }

    private async serverEvidence(): Promise<Record<string, unknown>> {
        const stat = await fs.promises.stat(this.options.serverPath);
        const evidence: Record<string, unknown> = {
            path: this.options.serverPath,
            cwd: this.options.serverCwd,
            bytes: stat.size,
            modifiedMs: stat.mtimeMs,
            sha256: await this.sha256File(this.options.serverPath),
        };
        for (const pdbName of ['digital_server.pdb', 'digital-server.pdb']) {
            const pdbPath = path.join(path.dirname(this.options.serverPath), pdbName);
            if (!fs.existsSync(pdbPath)) {
                continue;
            }
            const pdbStat = await fs.promises.stat(pdbPath);
            evidence.symbols = {
                path: pdbPath,
                bytes: pdbStat.size,
                modifiedMs: pdbStat.mtimeMs,
                sha256: await this.sha256File(pdbPath),
            };
            break;
        }
        return evidence;
    }

    private async writeIntegrityManifest(directory: string): Promise<void> {
        const files = await this.filesBelow(directory);
        const entries: Array<{ path: string; bytes: number; sha256: string }> = [];
        for (const relativePath of files) {
            if (relativePath === 'sha256sums.json') {
                continue;
            }
            const filePath = path.join(directory, relativePath);
            const stat = await fs.promises.stat(filePath);
            entries.push({
                path: relativePath.split(path.sep).join('/'),
                bytes: stat.size,
                sha256: await this.sha256File(filePath),
            });
        }
        await this.writeJson(path.join(directory, 'sha256sums.json'), {
            schema: `${evidenceSchema}.integrity`,
            generatedAt: new Date().toISOString(),
            files: entries,
        });
    }

    private async filesBelow(root: string): Promise<string[]> {
        const result: string[] = [];
        const pending = [''];
        while (pending.length > 0) {
            const relative = pending.pop();
            if (relative === undefined) {
                continue;
            }
            const entries = await fs.promises.readdir(path.join(root, relative), {
                withFileTypes: true,
            });
            for (const entry of entries) {
                const child = path.join(relative, entry.name);
                if (entry.isDirectory()) {
                    pending.push(child);
                } else if (entry.isFile()) {
                    result.push(child);
                }
            }
        }
        return result.sort();
    }

    private async openLatestEvidence(): Promise<void> {
        const latest = await this.findLatestEvidence();
        if (!latest) {
            void vscode.window.showInformationMessage('No Digital Server crash evidence is available.');
            return;
        }
        await vscode.commands.executeCommand('revealFileInOS', vscode.Uri.file(latest));
    }

    private async exportLatestEvidence(): Promise<void> {
        const latest = await this.findLatestEvidence();
        if (!latest) {
            void vscode.window.showInformationMessage('No Digital Server crash evidence is available.');
            return;
        }
        if (process.platform !== 'win32') {
            await this.openLatestEvidence();
            return;
        }
        const destination = await vscode.window.showSaveDialog({
            defaultUri: vscode.Uri.file(`${latest}.zip`),
            filters: { zip: ['zip'] },
            saveLabel: 'Export Crash Evidence',
        });
        if (!destination) {
            return;
        }
        await this.compressEvidence(latest, destination.fsPath);
        void vscode.window.showInformationMessage(
            `Digital Server crash evidence exported to ${destination.fsPath}`,
        );
    }

    private async compressEvidence(source: string, destination: string): Promise<void> {
        const command = [
            "$ErrorActionPreference = 'Stop'",
            'Compress-Archive -Path (Join-Path $args[0] \"*\") -DestinationPath $args[1] -Force',
        ].join('; ');
        await new Promise<void>((resolve, reject) => {
            childProcess.execFile(this.windowsPowerShellPath(), [
                '-NoLogo',
                '-NoProfile',
                '-NonInteractive',
                '-ExecutionPolicy',
                'Bypass',
                '-Command',
                command,
                source,
                destination,
            ], { windowsHide: true }, (error, _stdout, stderr) => {
                if (error) {
                    reject(new Error(stderr.trim() || error.message));
                } else {
                    resolve();
                }
            });
        });
    }

    private async findLatestEvidence(): Promise<string | undefined> {
        if (this.latestEvidence && fs.existsSync(this.latestEvidence)) {
            return this.latestEvidence;
        }
        try {
            const entries = await fs.promises.readdir(this.evidenceRoot, { withFileTypes: true });
            const directories = entries
                .filter(entry => entry.isDirectory())
                .map(entry => path.join(this.evidenceRoot, entry.name))
                .sort()
                .reverse();
            this.latestEvidence = directories[0];
            return this.latestEvidence;
        } catch {
            return undefined;
        }
    }

    private async pruneEvidence(): Promise<void> {
        const keep = Math.max(1, vscode.workspace
            .getConfiguration('digital-ide')
            .get<number>('function.lsp.crashForensics.retainedSessions', 3));
        const entries = await fs.promises.readdir(this.evidenceRoot, { withFileTypes: true });
        const directories = entries
            .filter(entry => entry.isDirectory())
            .map(entry => path.join(this.evidenceRoot, entry.name))
            .sort()
            .reverse();
        await Promise.all(directories.slice(keep).map(directory => fs.promises.rm(
            directory,
            { recursive: true, force: true },
        )));
    }

    private captureEnabled(): boolean {
        return vscode.workspace
            .getConfiguration('digital-ide')
            .get<boolean>('function.lsp.crashForensics.enabled', true);
    }

    private fullMemoryDumpEnabled(): boolean {
        return vscode.workspace
            .getConfiguration('digital-ide')
            .get<boolean>('function.lsp.crashForensics.fullMemoryDump', true);
    }

    private windowsPowerShellPath(): string {
        const systemRoot = process.env.SystemRoot ?? process.env.WINDIR;
        if (systemRoot) {
            const candidate = path.join(
                systemRoot,
                'System32',
                'WindowsPowerShell',
                'v1.0',
                'powershell.exe',
            );
            if (fs.existsSync(candidate)) {
                return candidate;
            }
        }
        return 'powershell.exe';
    }

    private async sha256File(filePath: string): Promise<string> {
        return new Promise((resolve, reject) => {
            const hash = crypto.createHash('sha256');
            const stream = fs.createReadStream(filePath);
            stream.on('data', chunk => hash.update(chunk));
            stream.once('error', reject);
            stream.once('end', () => resolve(hash.digest('hex')));
        });
    }

    private sha256Text(text: string): string {
        return crypto.createHash('sha256').update(text, 'utf8').digest('hex');
    }

    private async writeJson(filePath: string, value: unknown): Promise<void> {
        const temporary = `${filePath}.${process.pid}.tmp`;
        await fs.promises.writeFile(temporary, `${JSON.stringify(value, null, 2)}\n`, 'utf8');
        await fs.promises.rename(temporary, filePath);
    }

    private async readJsonIfPresent(filePath: string): Promise<unknown> {
        try {
            return JSON.parse(await fs.promises.readFile(filePath, 'utf8'));
        } catch {
            return null;
        }
    }

    private endStream(stream: fs.WriteStream): Promise<void> {
        return new Promise(resolve => stream.end(resolve));
    }

    private delay(milliseconds: number): Promise<void> {
        return new Promise(resolve => setTimeout(resolve, milliseconds));
    }
}
