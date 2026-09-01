const path = require('path');

const inspectorPort = Number(process.argv[2]);
const workspace = path.resolve(process.argv[3] ?? '');
const source = path.resolve(process.argv[4] ?? '');
const moduleName = process.argv[5] ?? '';

if (!Number.isInteger(inspectorPort) || inspectorPort < 1 || inspectorPort > 65535) {
    throw new Error('Netlist debug launch requires a valid Extension Host inspector port.');
}
if (!moduleName.trim()) {
    throw new Error('Netlist debug launch requires a module name.');
}
const relativeSource = path.relative(workspace, source);
if (!relativeSource || relativeSource.startsWith('..') || path.isAbsolute(relativeSource)) {
    throw new Error('Netlist debug source must be inside the target workspace.');
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
            () => reject(new Error('Timed out while opening the netlist Webview.')),
            120_000,
        );
        socket.addEventListener('message', event => {
            const message = JSON.parse(String(event.data));
            if (message.id !== 1) {
                return;
            }
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

const extensionEntry = path.resolve(__dirname, '..', 'out', 'extension.js');
const expression = `(async () => {
    const load = process.getBuiltinModule('module').createRequire(${JSON.stringify(extensionEntry)});
    const vscode = load('vscode');
    const source = vscode.Uri.file(${JSON.stringify(source)});
    let commandReady = false;
    for (let attempt = 0; attempt < 240; attempt += 1) {
        const commands = await vscode.commands.getCommands(true);
        if (commands.includes('digital-ide.netlist.show')) {
            commandReady = true;
            break;
        }
        await new Promise(resolve => setTimeout(resolve, 250));
    }
    if (!commandReady) {
        throw new Error('Digital IDE netlist command was not registered within 60 seconds.');
    }
    await vscode.commands.executeCommand('vscode.open', source);
    const response = await vscode.commands.executeCommand(
        'digital-ide.netlist.show',
        source,
        ${JSON.stringify(moduleName)},
    );
    if (!response?.success || !response.render?.graphs?.length) {
        throw new Error(response?.message ?? 'Digital Server returned no accepted drawing information.');
    }
    const degraded = response.render.graphs.filter(graph => graph.quality?.accepted !== true);
    await new Promise(resolve => setTimeout(resolve, 750));
    return {
        moduleName: response.moduleName,
        graphCount: response.render.graphs.length,
        degradedGraphCount: degraded.length,
        skinNames: response.render.graphs.flatMap(graph => graph.nodes)
            .filter(node => node.renderType === 'skin')
            .map(node => node.skin?.name)
            .filter(Boolean)
            .sort(),
    };
})()`;

evaluate(expression).then(result => {
    process.stdout.write(`Netlist Webview is visible: ${JSON.stringify(result)}\n`);
}).catch(error => {
    process.stderr.write(`error: failed to display netlist Webview: ${String(error)}\n`);
    process.exitCode = 1;
});
