const path = require('path');

const inspectorPort = Number(process.argv[2]);
const workspace = path.resolve(process.argv[3] ?? '');
if (!Number.isInteger(inspectorPort) || inspectorPort < 1 || inspectorPort > 65535) {
    throw new Error('Xilinx ILA demo requires a valid Extension Host inspector port.');
}

async function evaluate(expression) {
    const targets = await (await fetch(
        `http://127.0.0.1:${inspectorPort}/json/list`,
    )).json();
    const target = targets.find(candidate => candidate.type === 'node');
    if (!target?.webSocketDebuggerUrl) {
        throw new Error(`No Node inspector target is available on port ${inspectorPort}.`);
    }

    const socket = new WebSocket(target.webSocketDebuggerUrl);
    await new Promise((resolve, reject) => {
        socket.addEventListener('open', resolve, { once: true });
        socket.addEventListener('error', reject, { once: true });
    });
    const response = await new Promise((resolve, reject) => {
        const timeout = setTimeout(
            () => reject(new Error('Timed out while opening the Xilinx ILA demo.')),
            60_000,
        );
        socket.addEventListener('message', event => {
            const message = JSON.parse(String(event.data));
            if (message.id !== 1) return;
            clearTimeout(timeout);
            resolve(message);
        });
        socket.send(JSON.stringify({
            id: 1,
            method: 'Runtime.evaluate',
            params: {
                expression,
                awaitPromise: true,
                returnByValue: true,
            },
        }));
    });
    socket.close();
    const result = response.result?.result;
    if (response.result?.exceptionDetails) {
        throw new Error(response.result.exceptionDetails.exception?.description
            ?? response.result.exceptionDetails.text);
    }
    if (result?.subtype === 'error') {
        throw new Error(result.description ?? 'Extension Host evaluation failed.');
    }
    return result?.value;
}

const extensionEntry = path.resolve(__dirname, '..', '..', 'out', 'extension.js');
const artifact = path.join(workspace, 'prj', 'debugger', 'xilinx-ila-demo');
const fakeVivado = path.join(artifact, 'bin', 'vivado');
const expression = `(async () => {
    const load = process.getBuiltinModule('module').createRequire(${JSON.stringify(extensionEntry)});
    const vscode = load('vscode');
    const workspace = vscode.Uri.file(${JSON.stringify(workspace)});
    const artifactUri = vscode.Uri.file(${JSON.stringify(artifact)});
    const selector = {
        workspaceUri: workspace,
        artifactUri,
        vendor: 'vivado',
        top: 'xilinx_ila_demo_top'
    };
    let debuggerReady = false;
    for (let attempt = 0; attempt < 240; attempt += 1) {
        const commands = await vscode.commands.getCommands(true);
        if (commands.includes('digital-ide.debugger.capture')) {
            debuggerReady = true;
            break;
        }
        await new Promise(resolve => setTimeout(resolve, 250));
    }
    if (!debuggerReady) {
        throw new Error('Digital IDE debugger commands were not registered within 60 seconds.');
    }
    await vscode.commands.executeCommand('workbench.view.extension.TreeView');
    await vscode.commands.executeCommand('digital-ide.debugger.refresh', selector);
    await vscode.commands.executeCommand('digital-ide-treeView-debugger.focus');
    await new Promise(resolve => setTimeout(resolve, 500));
    await vscode.commands.executeCommand('digital-ide.debugger.capture', {
        ...selector,
        core: { kind: 'ila', id: 0 },
        transport: {
            backend: 'vivado',
            command: ${JSON.stringify(fakeVivado)},
            program: false,
            timeoutMs: 30000
        },
        silent: true
    });
    await new Promise(resolve => setTimeout(resolve, 500));
    await vscode.commands.executeCommand('workbench.view.extension.TreeView');
    await vscode.commands.executeCommand('digital-ide-treeView-debugger.focus');
    return { tree: ['capture_bus', 'control_bus'], capture: 'ILA 0 Capture' };
})()`;

evaluate(expression).then(result => {
    process.stdout.write(`Xilinx ILA demo is visible: ${JSON.stringify(result)}\n`);
}).catch(error => {
    process.stderr.write(`error: failed to display Xilinx ILA demo: ${String(error)}\n`);
    process.exitCode = 1;
});
