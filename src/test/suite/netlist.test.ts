import * as assert from 'assert';
import * as fs from 'fs';
import * as vscode from 'vscode';
import type { Browser, CDPSession } from 'puppeteer-core';
import { activateExtension, waitFor, workspaceUri } from './helpers';

interface NetlistSession {
    session: CDPSession;
    contextId: number;
}

interface WebviewFrameTree {
    frame: { id: string };
    childFrames?: WebviewFrameTree[];
}

interface NetlistCommandResponse {
    success: boolean;
    message: string;
    moduleName: string;
    outputDirectory: string;
    jsonPath: string;
    renderPath: string;
    graphDigest: string;
    render?: unknown;
}

suite('Netlist Webview integration', () => {
    test('runs HDL through Rust Yosys and the reference WASM renderer in the actual Webview', async function () {
        this.timeout(180_000);
        const rendererPort = process.env.DIGITAL_TEST_RENDERER_DEBUG_PORT;
        assert.ok(rendererPort, 'renderer debugging port is unavailable');
        const api = await activateExtension();
        assert.ok(api.netlist, 'Netlist panel manager is unavailable');
        await api.project?.refreshArchitecture();

        const { default: puppeteer } = await import('puppeteer-core');
        const browser = await puppeteer.connect({
            browserURL: `http://127.0.0.1:${rendererPort}`,
        });
        const runtimeErrors: string[] = [];
        let webview: NetlistSession | undefined;
        try {
            const source = workspaceUri('src/sv/webview.sv');
            const command = vscode.commands.executeCommand<NetlistCommandResponse>(
                'digital-ide.netlist.show',
                source,
                'webview',
            );
            const observedCommand = command.then(
                value => ({ value }),
                error => ({ error }),
            );
            webview = await waitForNetlistSession(browser, 'webview', runtimeErrors);
            const progress = await Promise.race([
                observedCommand,
                new Promise<{ diagnostics: unknown }>(resolve => setTimeout(async () => {
                    const diagnostics = await evaluateWebview<unknown>(webview as NetlistSession, `({
                        worker: window.__DIGITAL_NETLIST_WORKER__ ?? null,
                        runState: document.querySelector('#run-state')?.textContent,
                        canvasError: document.querySelector('#canvas-error')?.textContent,
                        resources: performance.getEntriesByType('resource').map(entry => entry.name),
                    })`).catch(error => ({ unavailable: String(error) }));
                    resolve({ diagnostics });
                }, 5_000)),
            ]);
            const outcome = 'diagnostics' in progress ? await observedCommand : progress;
            if ('error' in outcome) {
                let diagnostics: unknown;
                try {
                    diagnostics = await evaluateWebview<unknown>(webview, `({
                        ready: document.querySelector('#app')?.classList.contains('app-ready'),
                        runState: document.querySelector('#run-state')?.textContent,
                        canvasError: document.querySelector('#canvas-error')?.textContent,
                        bootstrap: Object.keys(window.__DIGITAL_NETLIST_BOOTSTRAP__ ?? {}),
                        runtime: window.__DIGITAL_NETLIST_RUNTIME__ ?? null,
                    })`);
                } catch (diagnosticError) {
                    diagnostics = { unavailable: String(diagnosticError) };
                }
                throw new Error(`${String(outcome.error)}; Progress=${JSON.stringify('diagnostics' in progress ? progress.diagnostics : null)}; Webview=${JSON.stringify(diagnostics)}; runtimeErrors=${JSON.stringify(runtimeErrors)}`);
            }
            const response = outcome.value;

            assert.strictEqual(response.success, true);
            assert.match(response.message, /Yosys JSON/);
            assert.strictEqual(response.moduleName, 'webview');
            assert.ok(fs.statSync(response.jsonPath).isFile());
            assert.strictEqual(response.renderPath, '');
            assert.strictEqual(response.render, undefined);
            const yosys = JSON.parse(fs.readFileSync(response.jsonPath, 'utf8')) as {
                modules?: Record<string, unknown>;
            };
            assert.ok(yosys.modules?.webview, 'Rust did not publish the requested Yosys module');
            assert.strictEqual(api.netlist.activePanelCount, 1);
            assert.strictEqual(
                vscode.window.tabGroups.activeTabGroup.activeTab?.label,
                'Netlist: webview',
            );

            const state = await evaluateWebview<{
                bootstrapKeys: string[];
                assetBaseUri: string;
                bootstrapModule: string;
                bootstrapHasYosys: boolean;
                bootstrapHasPath: boolean;
                renderer: string;
                input: string;
                worker: string;
                wasm: { semantic: boolean; placement: boolean; routing: boolean };
                module: string;
                nodes: number;
                paths: number;
                junctions: number;
                bounds: { width: number; height: number };
                status: string;
                netloomReady: boolean;
                avoidReady: boolean;
                quality: boolean;
                csp: string;
                resources: string[];
                canvasBackground: string;
            }>(webview, `(() => {
                const bootstrap = window.__DIGITAL_NETLIST_BOOTSTRAP__;
                const runtime = window.__DIGITAL_NETLIST_RUNTIME__;
                const bounds = document.querySelector('#viewport').getBBox();
                return {
                    bootstrapKeys: Object.keys(bootstrap ?? {}).sort(),
                    assetBaseUri: bootstrap?.assetBaseUri ?? '',
                    bootstrapModule: bootstrap?.moduleName ?? '',
                    bootstrapHasYosys: Boolean(bootstrap?.yosysJson?.modules?.webview),
                    bootstrapHasPath: 'jsonPath' in (bootstrap ?? {}),
                    renderer: runtime?.renderer ?? '',
                    input: runtime?.input ?? '',
                    worker: runtime?.worker ?? '',
                    wasm: runtime?.wasm ?? {},
                    module: document.querySelector('#module-select')?.value ?? '',
                    nodes: document.querySelectorAll('#viewport .net-node').length,
                    paths: document.querySelectorAll('#viewport .net-route-arc').length,
                    junctions: document.querySelectorAll('#viewport .net-junction').length,
                    bounds: { width: bounds.width, height: bounds.height },
                    status: document.querySelector('#run-state')?.textContent ?? '',
                    netloomReady: document.querySelector('#netloom-status')?.classList.contains('ready') ?? false,
                    avoidReady: document.querySelector('#avoid-status')?.classList.contains('ready') ?? false,
                    quality: (window.__NETLOOM_STATE__?.metrics?.quality?.accepted ?? false)
                        && Object.values(window.__NETLOOM_STATE__?.metrics?.quality?.checks ?? {})
                            .every(check => check.pass),
                    csp: document.querySelector('meta[http-equiv="Content-Security-Policy"]')?.content ?? '',
                    resources: performance.getEntriesByType('resource').map(entry => entry.name),
                    canvasBackground: getComputedStyle(document.querySelector('#canvas-panel')).backgroundColor,
                };
            })()`);

            assert.deepStrictEqual(state.bootstrapKeys, [
                'assetBaseUri',
                'moduleName',
                'protocolVersion',
                'sessionId',
                'sourceDigest',
                'sourceLabel',
                'yosysJson',
            ]);
            assert.strictEqual(state.bootstrapModule, 'webview');
            assert.strictEqual(state.bootstrapHasYosys, true);
            assert.strictEqual(state.bootstrapHasPath, false);
            assert.strictEqual(state.renderer, 'netloom-reference');
            assert.strictEqual(state.input, 'yosys-json');
            assert.strictEqual(state.worker, 'ready');
            assert.deepStrictEqual(state.wasm, {
                semantic: true,
                placement: true,
                routing: true,
            });
            assert.strictEqual(state.module, 'webview');
            assert.ok(state.nodes > 0, 'reference renderer produced no SVG nodes');
            assert.ok(state.paths > 0, 'reference renderer produced no SVG routes');
            assert.ok(state.bounds.width > 0 && state.bounds.height > 0, 'reference SVG is blank');
            assert.match(state.status, /^完成/);
            assert.strictEqual(state.netloomReady, true);
            assert.strictEqual(state.avoidReady, true);
            assert.strictEqual(state.quality, true);
            assert.strictEqual(state.canvasBackground, 'rgb(23, 23, 23)');

            const assetBase = new URL(state.assetBaseUri);
            assert.ok(
                assetBase.protocol === 'https:' || assetBase.protocol === 'vscode-webview-resource:',
                `unexpected Webview asset protocol: ${assetBase.protocol}`,
            );
            const assetBasePath = decodeURIComponent(assetBase.pathname);
            assert.ok(state.resources.some(resource => /layout\.worker-[^/]+\.js(?:$|[?#])/.test(resource)));
            for (const wasm of [
                'netloom_semantic_bg.wasm',
                'netloom-elk.wasm',
                'avoid.wasm',
            ]) {
                assert.ok(state.resources.some(resource => resource.includes(wasm)), `${wasm} was not loaded`);
            }
            assert.ok(state.resources.every(resource => {
                const url = new URL(resource);
                return !url.pathname.includes('/resources/netlist/')
                    || decodeURIComponent(url.pathname).startsWith(assetBasePath);
            }), 'a netlist resource escaped the published Webview root');
            assert.ok(state.csp.includes("'wasm-unsafe-eval'"));
            assert.ok(!state.csp.includes("connect-src 'none'"));
            assert.ok(!state.csp.includes("worker-src 'none'"));
            assert.ok(!state.csp.includes("'unsafe-inline'"));
            assert.deepStrictEqual(runtimeErrors, [], 'Webview console or page errors');
        } finally {
            if (webview) {
                await webview.session.detach().catch(() => undefined);
            }
            await browser.disconnect();
            await vscode.commands.executeCommand('workbench.action.closeActiveEditor');
            await waitFor(
                'Netlist Webview disposal',
                () => api.netlist?.activePanelCount ?? 0,
                count => count === 0,
                30_000,
            );
        }
    });
});

async function waitForNetlistSession(
    browser: Browser,
    moduleName: string,
    runtimeErrors: string[],
): Promise<NetlistSession> {
    const deadline = Date.now() + 60_000;
    while (Date.now() < deadline) {
        const targets = browser.targets().filter(target => (
            target.type() === 'other' && target.url().startsWith('vscode-webview://')
        ));
        for (const target of targets) {
            const session = await target.createCDPSession();
            const contexts: Array<{
                id: number;
                auxData?: { frameId?: string; isDefault?: boolean };
            }> = [];
            session.on('Runtime.executionContextCreated', event => contexts.push(event.context));
            session.on('Runtime.exceptionThrown', event => {
                runtimeErrors.push(event.exceptionDetails.exception?.description
                    ?? event.exceptionDetails.text);
            });
            session.on('Runtime.consoleAPICalled', event => {
                if (event.type === 'error') {
                    runtimeErrors.push(event.args.map((argument: {
                        value?: unknown;
                        description?: string;
                    }) => (
                        argument.value === undefined ? argument.description : String(argument.value)
                    )).join(' '));
                }
            });
            try {
                await session.send('Runtime.enable');
                await session.send('Page.enable');
                const frameTree = await session.send('Page.getFrameTree');
                for (const frameId of collectFrameIds(frameTree.frameTree)) {
                    const candidates = contexts.filter(context => (
                        context.auxData?.frameId === frameId && context.auxData.isDefault
                    ));
                    for (const context of candidates) {
                        const candidate = { session, contextId: context.id };
                        const matches = await evaluateWebview<boolean>(candidate, `
                            window.__DIGITAL_NETLIST_BOOTSTRAP__?.moduleName
                                === ${JSON.stringify(moduleName)}
                        `);
                        if (matches) {
                            return candidate;
                        }
                    }
                }
            } catch {
                // VS Code can replace a Webview target while committing the editor.
            }
            await session.detach();
        }
        await new Promise(resolve => setTimeout(resolve, 100));
    }
    throw new Error(`timed out waiting for the ${moduleName} reference netlist Webview`);
}

function collectFrameIds(tree: WebviewFrameTree): string[] {
    const ids = [tree.frame.id];
    for (const child of tree.childFrames ?? []) {
        ids.push(...collectFrameIds(child));
    }
    return ids;
}

async function evaluateWebview<T>(webview: NetlistSession, expression: string): Promise<T> {
    const response = await webview.session.send('Runtime.evaluate', {
        expression,
        contextId: webview.contextId,
        awaitPromise: true,
        returnByValue: true,
    });
    if (response.exceptionDetails) {
        throw new Error(
            response.exceptionDetails.exception?.description
            ?? response.exceptionDetails.text
            ?? 'Netlist Webview evaluation failed',
        );
    }
    return response.result.value as T;
}
