const fs = require('fs');
const os = require('os');
const path = require('path');
const vscode = require('vscode');

const requestRoot = path.join(os.homedir(), '.cache', 'digital-ide-current-window-controller');
const requestPattern = /^request-[A-Za-z0-9._-]+\.json$/;
let scanInProgress = false;

function requireString(config, name) {
    const value = config[name];
    if (typeof value !== 'string' || value.length === 0) {
        throw new Error(`Debug request field '${name}' must be a non-empty string.`);
    }
    return value;
}

function optionalPath(config, name) {
    const value = config[name];
    if (value === undefined || value === null || value === '') {
        return '';
    }
    if (typeof value !== 'string') {
        throw new Error(`Debug request field '${name}' must be a string.`);
    }
    return path.resolve(value);
}

function normalizeRequest(config) {
    const expiresAt = Number(config.expiresAt);
    if (!Number.isFinite(expiresAt)) {
        throw new Error("Debug request field 'expiresAt' must be a number.");
    }

    const statusPath = path.resolve(requireString(config, 'statusPath'));
    if (path.dirname(statusPath) !== requestRoot) {
        throw new Error('Debug request status path is outside the controller cache.');
    }

    return {
        sessionId: requireString(config, 'sessionId'),
        controllerWorkspacePath: path.resolve(requireString(config, 'controllerWorkspacePath')),
        extensionPath: path.resolve(requireString(config, 'extensionPath')),
        workspacePath: path.resolve(requireString(config, 'workspacePath')),
        activationFile: optionalPath(config, 'activationFile'),
        serverPath: path.resolve(requireString(config, 'serverPath')),
        vhdlLibraryPath: path.resolve(requireString(config, 'vhdlLibraryPath')),
        statusPath,
        expiresAt,
    };
}

function controlsWorkspace(request) {
    return vscode.workspace.workspaceFolders?.some(folder => (
        folder.uri.scheme === 'file'
        && path.resolve(folder.uri.fsPath) === request.controllerWorkspacePath
    )) ?? false;
}

async function writeStatus(request, state, details = {}) {
    const temporaryPath = `${request.statusPath}.${process.pid}.tmp`;
    const status = {
        sessionId: request.sessionId,
        state,
        controllerPid: process.pid,
        controllerWorkspaces: vscode.workspace.workspaceFolders?.map(folder => folder.uri.fsPath) ?? [],
        updatedAt: Date.now(),
        ...details,
    };
    await fs.promises.writeFile(temporaryPath, `${JSON.stringify(status, null, 2)}\n`, 'utf8');
    await fs.promises.rename(temporaryPath, request.statusPath);
}

async function launchRequest(requestPath, request) {
    const claimedPath = path.join(
        requestRoot,
        `claimed-${request.sessionId}-${process.pid}.json`,
    );
    try {
        await fs.promises.rename(requestPath, claimedPath);
    } catch (error) {
        if (error && error.code === 'ENOENT') {
            return;
        }
        throw error;
    }

    try {
        await writeStatus(request, 'claimed');
        const args = [
            `--extensionDevelopmentPath=${request.extensionPath}`,
            '--disable-extensions',
            request.workspacePath,
        ];
        if (request.activationFile) {
            args.push(request.activationFile);
        }
        args.push('--skip-release-notes', '--skip-welcome');
        const started = await vscode.debug.startDebugging(undefined, {
            name: `Digital IDE: ${request.workspacePath}`,
            type: 'extensionHost',
            request: 'launch',
            args,
            outFiles: [`${request.extensionPath}/out/**/*.js`],
            env: {
                DIGITAL_SERVER_PATH: request.serverPath,
                DIGITAL_SERVER_VHDL_LIBRARY_PATH: request.vhdlLibraryPath,
                RUST_BACKTRACE: '1',
            },
        });
        if (!started) {
            throw new Error('VS Code rejected the extension-host debug request.');
        }
        await writeStatus(request, 'started');
    } catch (error) {
        const message = error instanceof Error ? error.message : String(error);
        await writeStatus(request, 'error', { error: message });
        await vscode.window.showErrorMessage(`Digital IDE debug launch failed: ${message}`);
    } finally {
        await fs.promises.unlink(claimedPath).catch(() => undefined);
    }
}

async function scanRequests() {
    if (scanInProgress) {
        return;
    }
    scanInProgress = true;
    try {
        await fs.promises.mkdir(requestRoot, { recursive: true });
        const entries = await fs.promises.readdir(requestRoot);
        for (const entry of entries.filter(name => requestPattern.test(name)).sort()) {
            const requestPath = path.join(requestRoot, entry);
            let request;
            try {
                const contents = await fs.promises.readFile(requestPath, 'utf8');
                request = normalizeRequest(JSON.parse(contents));
            } catch (error) {
                await fs.promises.unlink(requestPath).catch(() => undefined);
                continue;
            }

            if (request.expiresAt <= Date.now()) {
                await fs.promises.unlink(requestPath).catch(() => undefined);
                continue;
            }
            if (controlsWorkspace(request)) {
                await launchRequest(requestPath, request);
            }
        }
    } finally {
        scanInProgress = false;
    }
}

function activate(context) {
    const scan = () => {
        void scanRequests().catch(async error => {
            const message = error instanceof Error ? error.message : String(error);
            await vscode.window.showErrorMessage(`Digital IDE controller failed: ${message}`);
        });
    };

    const timer = setInterval(scan, 250);
    context.subscriptions.push({ dispose: () => clearInterval(timer) });
    context.subscriptions.push(vscode.commands.registerCommand(
        'digitalIdeCurrentWindowController.scan',
        scan,
    ));
    scan();
}

exports.activate = activate;
