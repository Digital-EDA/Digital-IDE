import * as assert from 'assert';
import { execFileSync } from 'child_process';
import * as fs from 'fs';
import * as path from 'path';
import * as vscode from 'vscode';
import type { Browser, CDPSession, Page } from 'puppeteer-core';
import WebSocket = require('ws');
import type { SimulationResponse } from '../../simulation/commands';
import {
    AnsiOutputSanitizer,
    type WaveformDebugCommand,
    type WaveformDebugState,
} from '../../waveform/manager';
import { activateExtension, waitFor, workspaceUri } from './helpers';

suite('Waveform Webview integration', () => {
    const serverRoot = path.resolve(__dirname, '..', '..', '..', '..', '..');

    test('sanitizes split ANSI sequences without corrupting UTF-8 output', () => {
        const sanitizer = new AnsiOutputSanitizer();
        assert.strictEqual(sanitizer.push(Buffer.from('\x1b[2')), '');
        assert.strictEqual(sanitizer.push(Buffer.from('mINFO\x1b[0m 波')), 'INFO 波');
        const encoded = Buffer.from('形服务');
        assert.strictEqual(sanitizer.push(encoded.subarray(0, 2)), '');
        assert.strictEqual(sanitizer.push(encoded.subarray(2)), '形服务');
        assert.strictEqual(sanitizer.end(), '');
    });

    test('renders parameter values and signal pixels inside the actual VS Code Webview', async function () {
        this.timeout(120_000);
        const expectedRenderer = process.env.DIGITAL_VSCODE_TEST_FORCE_CANVAS === '1'
            ? 'canvas'
            : 'webgl';
        const rendererPort = process.env.DIGITAL_TEST_RENDERER_DEBUG_PORT;
        assert.ok(rendererPort, 'renderer debugging port is unavailable');
        const api = await activateExtension();
        const waveform = api.waveform;
        assert.ok(waveform, 'waveform extension API is unavailable');
        const source = path.join(serverRoot, 'tests/project/xilinx/temp/basic_tb.vcd');
        assert.ok(fs.existsSync(source), `missing waveform fixture: ${source}`);
        const target = workspaceUri('waveform/basic_tb.vcd');
        const toolbarTarget = workspaceUri('waveform/toolbar_open.vcd');
        const statePath = workspaceUri('waveform/toolbar_open.dws').fsPath;
        const missingStatePath = `${statePath}.missing-${Date.now()}`;
        await vscode.workspace.fs.createDirectory(vscode.Uri.file(path.dirname(target.fsPath)));
        await vscode.workspace.fs.writeFile(target, fs.readFileSync(source));
        await vscode.workspace.fs.writeFile(toolbarTarget, fs.readFileSync(source));
        if (fs.existsSync(statePath)) fs.unlinkSync(statePath);
        await vscode.workspace.getConfiguration('files').update(
            'simpleDialog.enable',
            true,
            vscode.ConfigurationTarget.Global,
        );
        await vscode.commands.executeCommand('workbench.action.closeSidebar');
        await vscode.commands.executeCommand('workbench.action.closeAuxiliaryBar');
        await vscode.commands.executeCommand('workbench.action.closePanel');

        await vscode.commands.executeCommand(
            'vscode.openWith',
            target,
            'digital-ide.waveformViewer',
            { preview: false },
        );
        await waitFor(
            'basic_tb waveform Webview ready handshake',
            () => waveform.activePanelCount,
            count => count === 1,
            30_000,
        );

        const { default: puppeteer } = await import('puppeteer-core');
        const browser = await puppeteer.connect({
            browserURL: `http://127.0.0.1:${rendererPort}`,
        });
        try {
            let webview = await waitForWaveformSession(browser, 'basic_tb');
            await assertGlobalFocusRingsSuppressed(webview);
            const workbench = (await browser.pages()).find(page => page.url().includes('workbench'));
            assert.ok(workbench, 'VS Code workbench page is unavailable');
            await waitForWorkbenchEditorChrome(workbench, 'DIDE-WAVE', 'basic_tb.vcd');
            assert.strictEqual(
                vscode.window.tabGroups.activeTabGroup.activeTab?.label,
                'DIDE-WAVE',
                'the waveform editor tab did not use its fixed product title',
            );
            await selectWaveformThroughWorkbenchDialog(webview, workbench, toolbarTarget.fsPath);
            await waitForWorkbenchEditorChrome(workbench, 'DIDE-WAVE', 'toolbar_open.vcd');
            await webview.session.detach().catch(() => undefined);
            webview = await waitForWaveformSession(browser, 'basic_tb');
            const toolbarSelectedPath = await waitForWebviewState<string>(webview, `(() => {
                const pinia = document.querySelector('#app')?.__vue_app__
                    ?.config?.globalProperties?.$pinia;
                return pinia?._s?.get('wave')?.filePath ?? '';
            })()`, value => value === toolbarTarget.fsPath);
            assert.strictEqual(toolbarSelectedPath, toolbarTarget.fsPath);

            await evaluateWebview<void>(webview, `(() => {
                const module = Array.from(document.querySelectorAll('.node-label'))
                    .find(element => element.innerText.trim() === 'basic_tb');
                if (!module) throw new Error('basic_tb hierarchy node is unavailable');
                module.dispatchEvent(new MouseEvent('click', { bubbles: true }));
            })()`);
            await waitForWebviewState<boolean>(webview, `
                Array.from(document.querySelectorAll('.signal-name'))
                    .some(element => element.innerText.trim() === 'ADDR_WIDTH')
            `);

            for (const signal of ['ADDR_WIDTH', 'sys_clk']) {
                await evaluateWebview<void>(webview, `(() => {
                    const name = ${JSON.stringify(signal)};
                    const element = Array.from(
                        document.querySelectorAll('.signal-name'),
                    ).find(candidate => candidate.innerText.trim() === name);
                    if (!element) throw new Error('signal ' + name + ' is unavailable');
                    element.dispatchEvent(new MouseEvent('dblclick', { bubbles: true }));
                })()`);
                await waitForWebviewState<boolean>(webview, `
                    Array.from(document.querySelectorAll('.signal-name-cell .signal-name'))
                        .some(element => element.innerText.includes(${JSON.stringify(signal)}))
                `);
            }

            const values = await waitForWebviewState<string[]>(webview, `
                Array.from(document.querySelectorAll('.value-text'))
                    .map(element => element.innerText.trim())
            `, value => value.length === 2 && value[0] === '8' && value[1] !== '--');
            assert.deepStrictEqual(values, ['8', '1']);

            await waitForWebviewState<boolean>(webview, `
                document.querySelector('.waveform-canvas')?.dataset.rendererBackend
                    === ${JSON.stringify(expectedRenderer)}
                    && Array.from(document.querySelectorAll('.waveform-canvas canvas'))
                        .some(canvas => canvas.width > 100 && canvas.height > 100)
            `);
            const pixelStats = await waitForWorkbenchWaveformPixels(workbench, webview);
            assert.ok(pixelStats.width > 100 && pixelStats.height > 100, 'waveform canvas is collapsed');
            assert.ok(
                pixelStats.parameterPixels > 5 && pixelStats.clockPixels > 100,
                `waveform canvas has no rendered tracks: ${JSON.stringify(pixelStats)}`,
            );

            const savedState = await evaluateWebview<{
                saved: boolean;
                tracks: string[];
                viewportStart: string;
                viewportEnd: string;
                cursorTime: string;
                statePath: string;
            }>(webview, `(async () => {
                const pinia = document.querySelector('#app')?.__vue_app__
                    ?.config?.globalProperties?.$pinia;
                const wave = pinia?._s?.get('wave');
                if (!wave) throw new Error('wave store is unavailable');
                const saved = await wave.saveSnapshot();
                return {
                    saved,
                    tracks: wave.tracks.map(track => track.name),
                    viewportStart: String(wave.viewportStart),
                    viewportEnd: String(wave.viewportEnd),
                    cursorTime: String(wave.cursorTime),
                    statePath: wave.statePath,
                };
            })()`);
            assert.strictEqual(savedState.saved, true, 'wave state was not saved');
            assert.strictEqual(
                savedState.statePath,
                statePath,
                'saving a directly opened VCD did not target its same-name .dws path',
            );
            assert.ok(fs.existsSync(statePath), 'the Wave backend did not create the .dws file');

            await evaluateWebview<void>(webview, `(() => {
                const pinia = document.querySelector('#app')?.__vue_app__
                    ?.config?.globalProperties?.$pinia;
                const wave = pinia?._s?.get('wave');
                if (!wave) throw new Error('wave store is unavailable');
                wave.tracks.splice(0, wave.tracks.length);
                wave.displayedItemTree.splice(0, wave.displayedItemTree.length);
                wave.viewportStart = 7n;
                wave.viewportEnd = 8n;
                wave.cursorTime = 7n;
            })()`);
            await waitForWebviewState<boolean>(webview, `
                document.querySelectorAll('.signal-name-cell .signal-name').length === 0
            `);

            const loaded = await evaluateWebview<boolean>(webview, `(async () => {
                const pinia = document.querySelector('#app')?.__vue_app__
                    ?.config?.globalProperties?.$pinia;
                const wave = pinia?._s?.get('wave');
                if (!wave) throw new Error('wave store is unavailable');
                return wave.loadSnapshot(${JSON.stringify(statePath)});
            })()`);
            assert.strictEqual(loaded, true, 'wave state was not loaded');
            const restoredState = await waitForWebviewState<{
                tracks: string[];
                viewportStart: string;
                viewportEnd: string;
                cursorTime: string;
                statusMessage: string;
            }>(webview, `(() => {
                const pinia = document.querySelector('#app')?.__vue_app__
                    ?.config?.globalProperties?.$pinia;
                const wave = pinia?._s?.get('wave');
                return {
                    tracks: wave?.tracks.map(track => track.name) ?? [],
                    viewportStart: String(wave?.viewportStart),
                    viewportEnd: String(wave?.viewportEnd),
                    cursorTime: String(wave?.cursorTime),
                    statusMessage: wave?.statusMessage ?? '',
                };
            })()`, state => state.tracks.length === 2
                && state.statusMessage.includes('波形状态已加载'));
            assert.deepStrictEqual(restoredState.tracks, savedState.tracks);
            assert.strictEqual(restoredState.viewportStart, savedState.viewportStart);
            assert.strictEqual(restoredState.viewportEnd, savedState.viewportEnd);
            assert.strictEqual(restoredState.cursorTime, savedState.cursorTime);
            const restoredValues = await waitForWebviewState<string[]>(webview, `
                Array.from(document.querySelectorAll('.value-text'))
                    .map(element => element.innerText.trim())
            `, value => value.length === 2 && value[0] === '8' && value[1] === '1');
            assert.deepStrictEqual(restoredValues, values);
            const restoredPixels = await waitForWorkbenchWaveformPixels(workbench, webview);
            assert.ok(
                restoredPixels.parameterPixels > 5 && restoredPixels.clockPixels > 100,
                `loaded state did not restore rendered tracks: ${JSON.stringify(restoredPixels)}`,
            );

            const failedLoadState = await evaluateWebview<{
                loaded: boolean;
                tracks: string[];
                viewportStart: string;
                viewportEnd: string;
                cursorTime: string;
                statusMessage: string;
            }>(webview, `(async () => {
                const pinia = document.querySelector('#app')?.__vue_app__
                    ?.config?.globalProperties?.$pinia;
                const wave = pinia?._s?.get('wave');
                if (!wave) throw new Error('wave store is unavailable');
                const loaded = await wave.loadSnapshot(${JSON.stringify(missingStatePath)});
                return {
                    loaded,
                    tracks: wave.tracks.map(track => track.name),
                    viewportStart: String(wave.viewportStart),
                    viewportEnd: String(wave.viewportEnd),
                    cursorTime: String(wave.cursorTime),
                    statusMessage: wave.statusMessage,
                };
            })()`);
            assert.strictEqual(failedLoadState.loaded, false, 'a missing state file was accepted');
            assert.ok(
                failedLoadState.statusMessage.includes('加载波形状态失败'),
                `failed Load State did not report an error: ${failedLoadState.statusMessage}`,
            );
            assert.deepStrictEqual(failedLoadState.tracks, savedState.tracks);
            assert.strictEqual(failedLoadState.viewportStart, savedState.viewportStart);
            assert.strictEqual(failedLoadState.viewportEnd, savedState.viewportEnd);
            assert.strictEqual(failedLoadState.cursorTime, savedState.cursorTime);
            const pixelsAfterFailedLoad = await waitForWorkbenchWaveformPixels(workbench, webview);
            assert.ok(
                pixelsAfterFailedLoad.parameterPixels > 5 && pixelsAfterFailedLoad.clockPixels > 100,
                `failed Load State cleared rendered tracks: ${JSON.stringify(pixelsAfterFailedLoad)}`,
            );

            if (process.platform === 'linux') {
                const processes = execFileSync('ps', ['-eo', 'pid=,ppid=,comm='], {
                    encoding: 'utf8',
                })
                    .split('\n')
                    .map(line => line.match(/^\s*(\d+)\s+(\d+)\s+(.+?)\s*$/))
                    .filter((match): match is RegExpMatchArray => match !== null)
                    .map(match => ({
                        pid: Number(match[1]),
                        parentPid: Number(match[2]),
                        command: match[3],
                    }));
                const descendants = new Set<number>([process.pid]);
                let previousSize = -1;
                while (descendants.size !== previousSize) {
                    previousSize = descendants.size;
                    for (const candidate of processes) {
                        if (descendants.has(candidate.parentPid)) {
                            descendants.add(candidate.pid);
                        }
                    }
                }
                const extensionProcesses = processes.filter(candidate => (
                    descendants.has(candidate.pid)
                ));
                assert.strictEqual(
                    extensionProcesses.filter(candidate => candidate.command === 'wave-server').length,
                    0,
                    'the extension launched a standalone wave-server process',
                );
                assert.strictEqual(
                    extensionProcesses.filter(candidate => candidate.command === 'digital-server').length,
                    1,
                    'the extension must use exactly one digital-server process',
                );
            }

            await webview.session.detach();
            await vscode.commands.executeCommand('workbench.action.closeActiveEditor');
            await waitFor(
                'source waveform Webview disposal before opening its state document',
                () => waveform.activePanelCount,
                count => count === 0,
            );
            await vscode.commands.executeCommand(
                'vscode.open',
                vscode.Uri.file(statePath),
                { preview: false },
            );
            await waitFor(
                'direct .dws waveform Webview ready handshake',
                () => waveform.activePanelCount,
                count => count === 1,
                30_000,
            );
            assert.strictEqual(
                vscode.window.tabGroups.activeTabGroup.activeTab?.label,
                'DIDE-WAVE',
                'opening .dws did not select the waveform Custom Editor',
            );
            await waitForWorkbenchEditorChrome(
                workbench,
                'DIDE-WAVE',
                path.basename(statePath),
            );

            const stateWebview = await waitForWaveformSession(browser, 'basic_tb');
            const directlyRestored = await waitForWebviewState<{
                tracks: string[];
                viewportStart: string;
                viewportEnd: string;
                cursorTime: string;
                statusMessage: string;
            }>(stateWebview, `(() => {
                const pinia = document.querySelector('#app')?.__vue_app__
                    ?.config?.globalProperties?.$pinia;
                const wave = pinia?._s?.get('wave');
                return {
                    tracks: wave?.tracks.map(track => track.name) ?? [],
                    viewportStart: String(wave?.viewportStart),
                    viewportEnd: String(wave?.viewportEnd),
                    cursorTime: String(wave?.cursorTime),
                    statusMessage: wave?.statusMessage ?? '',
                };
            })()`, state => state.tracks.length === 2
                && state.statusMessage.includes('波形状态已加载'));
            assert.deepStrictEqual(directlyRestored.tracks, savedState.tracks);
            assert.strictEqual(directlyRestored.viewportStart, savedState.viewportStart);
            assert.strictEqual(directlyRestored.viewportEnd, savedState.viewportEnd);
            assert.strictEqual(directlyRestored.cursorTime, savedState.cursorTime);
            const directlyRestoredPixels = await waitForWorkbenchWaveformPixels(
                workbench,
                stateWebview,
            );
            assert.ok(
                directlyRestoredPixels.parameterPixels > 5
                    && directlyRestoredPixels.clockPixels > 100,
                `opening .dws did not render its saved tracks: ${JSON.stringify(directlyRestoredPixels)}`,
            );
        } finally {
            await browser.disconnect();
            await vscode.commands.executeCommand('workbench.action.closeActiveEditor');
            await waitFor(
                'basic_tb waveform Webview disposal',
                () => waveform.activePanelCount,
                count => count === 0,
            );
        }
    });

    test('renders and dispatches the six hardware Debug interactions in order', async function () {
        this.timeout(120_000);
        const rendererPort = process.env.DIGITAL_TEST_RENDERER_DEBUG_PORT;
        assert.ok(rendererPort, 'renderer debugging port is unavailable');
        const api = await activateExtension();
        const waveform = api.waveform;
        assert.ok(waveform, 'waveform extension API is unavailable');

        const commands: WaveformDebugCommand[] = [];
        let captureTarget: Awaited<ReturnType<typeof waveform.openCapture>> | undefined;
        let state: WaveformDebugState = {
            connected: true,
            busy: false,
            status: 'idle',
            statusMessage: 'Ready',
            samplingMode: 'single',
            completedCaptures: 0,
            trigger: { expression: 'valid == 1', position: 32 },
        };
        const publishForCommand = async (command: WaveformDebugCommand): Promise<void> => {
            commands.push(command);
            if (!captureTarget) throw new Error('Debug capture target is unavailable');
            if (command.command === 'configureTrigger') {
                assert.ok(command.trigger, 'configureTrigger omitted its configuration');
                state = {
                    ...state,
                    statusMessage: 'Trigger configuration applied',
                    trigger: { ...command.trigger },
                };
            } else if (command.command === 'loopTrigger') {
                state = {
                    ...state,
                    busy: true,
                    status: 'waiting',
                    statusMessage: 'Waiting for hardware trigger condition',
                    samplingMode: 'continuous',
                };
            } else if (command.command === 'pauseTrigger') {
                state = {
                    ...state,
                    busy: false,
                    status: 'paused',
                    statusMessage: 'Trigger capture paused',
                    samplingMode: 'continuous',
                };
            } else if (command.command === 'disconnect') {
                state = {
                    ...state,
                    connected: false,
                    busy: false,
                    status: 'disconnected',
                    statusMessage: 'Hardware debugger disconnected',
                };
            } else {
                state = {
                    ...state,
                    busy: false,
                    status: 'captured',
                    statusMessage: 'Captured 64 samples',
                    samplingMode: 'single',
                    completedCaptures: state.completedCaptures + 1,
                    lastCapture: { samples: 64, signals: 2, timeRange: [0, 63] },
                };
            }
            await captureTarget.updateDebugState(state);
        };

        captureTarget = await waveform.openCapture(
            {
                vendor: 'vivado',
                coreId: 2,
                coreLabel: 'control_ila',
                dataDepth: 64,
                probes: [
                    { name: 'state', width: 4 },
                    { name: 'valid', width: 1 },
                ],
                triggerCondition: 'valid == 1',
                triggerEditable: true,
                triggerPosition: 32,
            },
            publishForCommand,
            'Debug Interaction Contract',
        );
        await captureTarget.updateDebugState(state);

        const { default: puppeteer } = await import('puppeteer-core');
        const browser = await puppeteer.connect({
            browserURL: `http://127.0.0.1:${rendererPort}`,
        });
        let webview: WaveformSession | undefined;
        try {
            webview = await waitForWaveformSession(browser, '');
            const controlOrder = await evaluateWebview<string[]>(webview, `
                Array.from(document.querySelectorAll('.debug-controls img'))
                    .map(image => image.getAttribute('alt') ?? '')
            `);
            assert.deepStrictEqual(controlOrder, [
                'debug-reset-trigger',
                'debug-program-trigger',
                'debug-loop-trigger',
                'debug-pause-trigger',
                'debug-single-trigger',
                'debug-stop-disconnect',
            ]);
            assert.strictEqual(await evaluateWebview<boolean>(webview, `
                Boolean(document.querySelector('.run-time-input'))
            `), false, 'simulation time controls leaked into Debug mode');

            await evaluateWebview<void>(webview, `(() => {
                const tab = document.querySelectorAll('.nav-icon-btn')[1];
                if (!(tab instanceof HTMLButtonElement) || tab.disabled) {
                    throw new Error('Debug trigger panel tab is unavailable');
                }
                tab.click();
            })()`);
            await waitForWebviewState<boolean>(webview, `
                document.querySelector('.debug-trigger-panel')?.getBoundingClientRect().height > 0
            `);
            await evaluateWebview<void>(webview, `(() => {
                const inputs = document.querySelectorAll('.debug-trigger-panel .field-input');
                const expression = inputs[0];
                const position = inputs[1];
                if (!(expression instanceof HTMLInputElement)
                    || !(position instanceof HTMLInputElement)) {
                    throw new Error('Debug trigger inputs are unavailable');
                }
                expression.value = 'state == 7';
                expression.dispatchEvent(new Event('input', { bubbles: true }));
                position.value = '48';
                position.dispatchEvent(new Event('input', { bubbles: true }));
            })()`);
            await waitForWebviewState<boolean>(webview, `
                Boolean(document.querySelector('.debug-trigger-panel .apply-btn:not(:disabled)'))
            `);
            await evaluateWebview<void>(webview, `(() => {
                const apply = document.querySelector('.debug-trigger-panel .apply-btn');
                if (!(apply instanceof HTMLButtonElement) || apply.disabled) {
                    throw new Error('Debug trigger Apply button is unavailable');
                }
                apply.click();
            })()`);
            await waitFor('Debug trigger configuration command', () => commands.length, length => length === 1);
            assert.deepStrictEqual(commands[0], {
                command: 'configureTrigger',
                trigger: { expression: 'state == 7', position: 48 },
            });

            const clickDebugControl = async (alt: string, expectedCount: number): Promise<void> => {
                await evaluateWebview<void>(webview!, `(() => {
                    const button = document.querySelector(
                        ${JSON.stringify(`.debug-controls img[alt="${alt}"]`)}
                    )?.closest('button');
                    if (!(button instanceof HTMLButtonElement) || button.disabled) {
                        throw new Error(${JSON.stringify(`Debug control ${alt} is unavailable`)});
                    }
                    button.click();
                })()`);
                await waitFor(
                    `Debug control ${alt}`,
                    () => commands.length,
                    length => length === expectedCount,
                );
                await waitForWebviewState<boolean>(webview!, `(() => {
                    const pinia = document.querySelector('#app')?.__vue_app__
                        ?.config?.globalProperties?.$pinia;
                    const debug = pinia?._s?.get('debug');
                    return debug ? !debug.commandPending : false;
                })()`);
            };

            await clickDebugControl('debug-reset-trigger', 2);
            await clickDebugControl('debug-program-trigger', 3);
            await clickDebugControl('debug-loop-trigger', 4);
            const loopState = await waitForWebviewState<{
                mode: string;
                status: string;
                busy: boolean;
            }>(webview, `(() => {
                const pinia = document.querySelector('#app')?.__vue_app__
                    ?.config?.globalProperties?.$pinia;
                const debug = pinia?._s?.get('debug');
                return {
                    mode: debug?.state.samplingMode ?? '',
                    status: debug?.state.status ?? '',
                    busy: Boolean(debug?.state.busy),
                };
            })()`, value => value.mode === 'continuous'
                && value.status === 'waiting'
                && value.busy);
            assert.deepStrictEqual(loopState, {
                mode: 'continuous',
                status: 'waiting',
                busy: true,
            });
            await clickDebugControl('debug-pause-trigger', 5);
            await clickDebugControl('debug-single-trigger', 6);
            await clickDebugControl('debug-stop-disconnect', 7);
            assert.deepStrictEqual(commands.map(command => command.command), [
                'configureTrigger',
                'resetTrigger',
                'programAndTrigger',
                'loopTrigger',
                'pauseTrigger',
                'singleTrigger',
                'disconnect',
            ]);
            const finalState = await waitForWebviewState<{
                connected: boolean;
                mode: string;
                status: string;
                expression: string;
                position: number;
            }>(webview, `(() => {
                const pinia = document.querySelector('#app')?.__vue_app__
                    ?.config?.globalProperties?.$pinia;
                const debug = pinia?._s?.get('debug');
                return {
                    connected: Boolean(debug?.state.connected),
                    mode: debug?.state.samplingMode ?? '',
                    status: debug?.state.status ?? '',
                    expression: debug?.state.trigger.expression ?? '',
                    position: debug?.state.trigger.position ?? -1,
                };
            })()`, value => !value.connected && value.status === 'disconnected');
            assert.deepStrictEqual(finalState, {
                connected: false,
                mode: 'single',
                status: 'disconnected',
                expression: 'state == 7',
                position: 48,
            });
        } finally {
            if (webview) await webview.session.detach();
            captureTarget.panel.dispose();
            await browser.disconnect();
            await waitFor(
                'Debug waveform Webview disposal',
                () => waveform.activePanelCount,
                count => count === 0,
            );
        }
    });

    test('exports the visible waveform tracks as WaveDrom JSON', async function () {
        this.timeout(90_000);
        const rendererPort = process.env.DIGITAL_TEST_RENDERER_DEBUG_PORT;
        assert.ok(rendererPort, 'renderer debugging port is unavailable');
        const api = await activateExtension();
        const waveform = api.waveform;
        assert.ok(waveform, 'waveform extension API is unavailable');

        const source = workspaceUri('waveform/wavedrom_export.vcd');
        await vscode.workspace.fs.createDirectory(vscode.Uri.file(path.dirname(source.fsPath)));
        await vscode.workspace.fs.writeFile(source, Buffer.from(
            '$date today $end\n'
            + '$version digital-ide test $end\n'
            + '$timescale 1ns $end\n'
            + '$scope module export_tb $end\n'
            + '$var wire 1 ! clk $end\n'
            + '$var wire 2 " data [1:0] $end\n'
            + '$upscope $end\n'
            + '$enddefinitions $end\n'
            + '#0\n'
            + '$dumpvars\n'
            + '0!\n'
            + 'b00 "\n'
            + '$end\n'
            + '#5\n'
            + '1!\n'
            + 'b01 "\n'
            + '#10\n'
            + '0!\n'
            + 'b10 "\n',
        ));
        await vscode.commands.executeCommand(
            'vscode.openWith',
            source,
            'digital-ide.waveformViewer',
            { preview: false },
        );
        await waitFor(
            'WaveDrom export waveform Webview ready handshake',
            () => waveform.activePanelCount,
            count => count === 1,
            30_000,
        );

        const { default: puppeteer } = await import('puppeteer-core');
        const browser = await puppeteer.connect({
            browserURL: `http://127.0.0.1:${rendererPort}`,
        });
        try {
            const webview = await waitForWaveformSession(browser, 'export_tb');
            await evaluateWebview<void>(webview, `(() => {
                const module = Array.from(document.querySelectorAll('.node-label'))
                    .find(element => element.innerText.trim() === 'export_tb');
                if (!module) throw new Error('export_tb hierarchy node is unavailable');
                module.dispatchEvent(new MouseEvent('click', { bubbles: true }));
            })()`);
            await waitForWebviewState<boolean>(webview, `
                Array.from(document.querySelectorAll('.signal-list .signal-name'))
                    .some(element => element.innerText.trim() === 'data')
            `);
            await evaluateWebview<void>(webview, `(() => {
                const signal = Array.from(document.querySelectorAll('.signal-list .signal-name'))
                    .find(element => element.innerText.trim() === 'data');
                if (!signal) throw new Error('data signal is unavailable');
                signal.dispatchEvent(new MouseEvent('dblclick', { bubbles: true }));
            })()`);
            await waitForWebviewState<number>(webview, `(() => {
                const wave = document.querySelector('#app')?.__vue_app__
                    ?.config?.globalProperties?.$pinia?._s?.get('wave');
                return wave?.tracks.length ?? 0;
            })()`, count => count === 1);
            const trackDiagnostics = await evaluateWebview<unknown>(webview, `(() => {
                const wave = document.querySelector('#app')?.__vue_app__
                    ?.config?.globalProperties?.$pinia?._s?.get('wave');
                const track = wave?.tracks[0];
                return {
                    filePath: wave?.filePath,
                    timeRange: [String(wave?.timeRangeStart), String(wave?.timeRangeEnd)],
                    track: track ? {
                        id: track.id,
                        variableId: track.variableId,
                        format: track.format,
                        value: wave.getValueAtCursor(track.id),
                    } : null,
                    values: Array.from(document.querySelectorAll('.value-text'))
                        .map(element => element.innerText.trim()),
                };
            })()`);

            const exported = await evaluateWebview<{ json: string | null; status: string }>(
                webview,
                `(async () => {
                    const wave = document.querySelector('#app')?.__vue_app__
                        ?.config?.globalProperties?.$pinia?._s?.get('wave');
                    if (!wave) throw new Error('wave store is unavailable');
                    const json = await wave.exportRoiToWaveDrom();
                    return { json, status: wave.statusMessage };
                })()`,
            );
            const sentMessages = await evaluateWebview<string[]>(webview, `
                globalThis.__digitalWaveformTestDiagnostics?.sent ?? []
            `);
            assert.ok(
                exported.json,
                `WaveDrom export returned no data: ${exported.status}; diagnostics=${JSON.stringify(trackDiagnostics)}`,
            );
            const document = JSON.parse(exported.json) as {
                signal?: Array<{ name?: string; wave?: string; data?: string[] }>;
            };
            assert.ok(Array.isArray(document.signal), 'WaveDrom document has no signal array');
            const dataSignal = document.signal.find(signal => signal.name === 'export_tb.data');
            assert.ok(
                dataSignal,
                `WaveDrom document did not contain the selected track: ${exported.json}; diagnostics=${JSON.stringify(trackDiagnostics)}; sent=${JSON.stringify(sentMessages)}`,
            );
            assert.ok(dataSignal.wave?.includes('='), `WaveDrom bus was not encoded as data: ${exported.json}`);
            assert.deepStrictEqual(dataSignal.data, ['0x0', '0x1', '0x2']);
        } finally {
            await browser.disconnect();
            await vscode.commands.executeCommand('workbench.action.closeActiveEditor');
            await waitFor(
                'WaveDrom export waveform Webview disposal',
                () => waveform.activePanelCount,
                count => count === 0,
            );
        }
    });

    test('preserves selected waveform tracks when a single hardware trigger replaces the capture', async function () {
        this.timeout(120_000);
        const rendererPort = process.env.DIGITAL_TEST_RENDERER_DEBUG_PORT;
        assert.ok(rendererPort, 'renderer debugging port is unavailable');
        const api = await activateExtension();
        const waveform = api.waveform;
        assert.ok(waveform, 'waveform extension API is unavailable');

        const commands: WaveformDebugCommand[] = [];
        let captureTarget: Awaited<ReturnType<typeof waveform.openCapture>> | undefined;
        captureTarget = await waveform.openCapture(
            {
                vendor: 'vivado',
                coreId: 3,
                coreLabel: 'capture_state_ila',
                dataDepth: 64,
                probes: [
                    { name: 'counter', width: 4 },
                    { name: 'valid', width: 1 },
                ],
                triggerCondition: 'valid == 1',
                triggerEditable: true,
                triggerPosition: 32,
            },
            async command => {
                commands.push(command);
                if (command.command === 'singleTrigger') {
                    await publishTestHardwareCapture(
                        captureTarget!.waveformUrl,
                        'single-trigger-2',
                        index => ({ counter: 15 - (index % 16), valid: index < 32 ? 1 : 0 }),
                    );
                }
            },
            'Capture State Preservation',
        );
        await publishTestHardwareCapture(
            captureTarget.waveformUrl,
            'single-trigger-1',
            index => ({ counter: index % 16, valid: index % 2 }),
        );

        const { default: puppeteer } = await import('puppeteer-core');
        const browser = await puppeteer.connect({
            browserURL: `http://127.0.0.1:${rendererPort}`,
        });
        let webview: WaveformSession | undefined;
        try {
            webview = await waitForWaveformSession(browser, '');
            await waitForWebviewState<boolean>(webview, `(() => {
                const pinia = document.querySelector('#app')?.__vue_app__
                    ?.config?.globalProperties?.$pinia;
                const wave = pinia?._s?.get('wave');
                return wave?.activeCaptureName === 'single-trigger-1'
                    && wave.hierarchy.some(scope => scope.name === 'capture');
            })()`);
            await evaluateWebview<void>(webview, `(async () => {
                const pinia = document.querySelector('#app')?.__vue_app__
                    ?.config?.globalProperties?.$pinia;
                const wave = pinia?._s?.get('wave');
                if (!wave) throw new Error('wave store is unavailable');
                await wave.addSignal('capture.ila.counter', 'counter', 4, 'capture.ila.counter', 'bits');
                await new Promise(resolve => setTimeout(resolve, 5));
                await wave.addSignal('capture.ila.valid', 'valid', 1, 'capture.ila.valid', 'bool');
                const counter = wave.tracks.find(track => track.variableId === 'capture.ila.counter');
                const valid = wave.tracks.find(track => track.variableId === 'capture.ila.valid');
                if (!counter || !valid) throw new Error('capture tracks were not added');
                counter.format = 'unsigned';
                counter.color = '#ff6b6b';
                counter.height = 46;
                counter.isAnalog = true;
                counter.analogMode = 'step';
                const groupId = wave.createGroup('Captured control', [counter.id, valid.id]);
                wave.selectedTrackIds = new Set([counter.id]);
                const validNode = wave.displayedItemTree.find(node => node.itemId === valid.id);
                if (validNode) validNode.selected = true;
                wave.setCompareSource(counter.id);
                wave.requestRenderUpdate();
                if (!wave.groups.has(groupId)) throw new Error('capture group was not created');
            })()`);

            const before = await waitForWebviewState<CaptureDisplayState>(
                webview,
                captureDisplayStateExpression(),
                value => value.captureName === 'single-trigger-1'
                    && value.tracks.length === 2
                    && value.renderGeneration > 0
                    && value.renderSignature.length === 2,
            );

            await clickWebviewToolbarButton(webview, 'debug-single-trigger');
            await waitFor('single hardware trigger command', () => commands.length, length => length === 1);
            assert.strictEqual(commands[0].command, 'singleTrigger');

            const after = await waitForWebviewState<CaptureDisplayState>(
                webview,
                captureDisplayStateExpression(),
                value => value.captureName === 'single-trigger-2'
                    && value.renderGeneration > before.renderGeneration
                    && value.renderSignature.length === 2,
            );
            assert.deepStrictEqual(after.tracks, before.tracks);
            assert.deepStrictEqual(after.selectedTrackIds, before.selectedTrackIds);
            assert.deepStrictEqual(after.groups, before.groups);
            assert.deepStrictEqual(after.displayedItemTree, before.displayedItemTree);
            assert.strictEqual(after.compareSourceId, null);
            assert.notDeepStrictEqual(after.renderSignature, before.renderSignature);
        } finally {
            if (webview) await webview.session.detach();
            captureTarget.panel.dispose();
            await browser.disconnect();
            await waitFor(
                'Capture preservation Webview disposal',
                () => waveform.activePanelCount,
                count => count === 0,
            );
        }
    });

    test('pre-runs Verilator for 100 ns and renders a signal selected afterwards', async function () {
        this.timeout(180_000);
        const rendererPort = process.env.DIGITAL_TEST_RENDERER_DEBUG_PORT;
        assert.ok(rendererPort, 'renderer debugging port is unavailable');
        const api = await activateExtension();
        const waveform = api.waveform;
        assert.ok(waveform, 'waveform extension API is unavailable');
        const source = workspaceUri('src/sv/pre_run_history_tb.sv');
        await vscode.workspace.fs.createDirectory(vscode.Uri.file(path.dirname(source.fsPath)));
        await vscode.workspace.fs.writeFile(source, Buffer.from(
            '`timescale 1ns/1ps\n'
            + 'module pre_run_history_tb;\n'
            + 'logic clk = 1\'b0;\n'
            + 'logic q = 1\'b0;\n'
            + 'always #5 clk = ~clk;\n'
            + 'always @(posedge clk) q <= ~q;\n'
            + 'endmodule\n',
        ));
        const response = await vscode.commands.executeCommand<SimulationResponse>(
            'digital-ide.tool.simulateFile',
            {
                fileUri: source,
                moduleName: 'pre_run_history_tb',
                backend: 'verilator',
                silent: true,
                options: { vendorPrepare: false },
            },
        );
        assert.strictEqual(response.success, true);
        assert.strictEqual(response.backend, 'verilator');
        await waitFor(
            'Verilator pre-run waveform panel',
            () => waveform.activePanelCount,
            count => count === 1,
            30_000,
        );

        const { default: puppeteer } = await import('puppeteer-core');
        const browser = await puppeteer.connect({
            browserURL: `http://127.0.0.1:${rendererPort}`,
        });
        let webview: WaveformSession | undefined;
        try {
            webview = await waitForWaveformSession(browser, '');
            const preRunState = await waitForRemoteRunState(webview, 100, false);
            assert.strictEqual(preRunState.error, null);

            const signal = await waitForWebviewState<{
                variableId: string;
                width: number;
            }>(webview, `(() => {
                const pinia = document.querySelector('#app')?.__vue_app__
                    ?.config?.globalProperties?.$pinia;
                const remote = pinia?._s?.get('remoteSimulator');
                const signal = remote?.availableSignals.find(candidate => candidate.name === 'q');
                return {
                    variableId: signal ? [...signal.path, signal.name].join('.') : '',
                    width: signal?.width ?? 0,
                };
            })()`, value => Boolean(value.variableId && value.width === 1));

            await evaluateWebview<void>(webview, `(async () => {
                const pinia = document.querySelector('#app')?.__vue_app__
                    ?.config?.globalProperties?.$pinia;
                const wave = pinia?._s?.get('wave');
                if (!wave) throw new Error('wave store is unavailable');
                await wave.addSignal(
                    ${JSON.stringify(signal.variableId)},
                    'q',
                    ${signal.width},
                    'pre_run_history_tb',
                );
            })()`);
            await waitForRemoteRunState(webview, 100, true);

            const workbench = (await browser.pages()).find(page => page.url().includes('workbench'));
            assert.ok(workbench, 'VS Code workbench page is unavailable');
            const expectedRenderer = process.env.DIGITAL_VSCODE_TEST_FORCE_CANVAS === '1'
                ? 'canvas'
                : 'webgl';
            await waitForWebviewState<boolean>(webview, `
                document.querySelector('.waveform-canvas')?.dataset.rendererBackend
                    === ${JSON.stringify(expectedRenderer)}
            `);
            const bitPixels = await waitForWorkbenchBitPixels(workbench, webview);
            assert.ok(bitPixels > 100, 'the post-selected signal has no 0-100 ns waveform pixels');
        } finally {
            if (webview) await webview.session.detach();
            await browser.disconnect();
            await vscode.commands.executeCommand('workbench.action.closeActiveEditor');
            await waitFor(
                'Verilator pre-run waveform disposal',
                () => waveform.activePanelCount,
                count => count === 0,
            );
        }
    });

    test('gates and applies an immutable stimulus snapshot on the next Verilator run', async function () {
        this.timeout(180_000);
        const rendererPort = process.env.DIGITAL_TEST_RENDERER_DEBUG_PORT;
        assert.ok(rendererPort, 'renderer debugging port is unavailable');
        const api = await activateExtension();
        const waveform = api.waveform;
        assert.ok(waveform, 'waveform extension API is unavailable');
        const source = workspaceUri('src/sv/stimulus_snapshot_contract.sv');
        await vscode.workspace.fs.createDirectory(vscode.Uri.file(path.dirname(source.fsPath)));
        await vscode.workspace.fs.writeFile(source, Buffer.from(
            'module stimulus_snapshot_contract(\n'
            + '    input logic clk, input logic rst, output logic q\n'
            + ');\n'
            + 'always_ff @(posedge clk or posedge rst) begin\n'
            + '    if (rst) q <= 1\'b0; else q <= ~q;\n'
            + 'end\n'
            + 'endmodule\n',
        ));
        const response = await vscode.commands.executeCommand<SimulationResponse>(
            'digital-ide.tool.simulateFile',
            {
                fileUri: source,
                moduleName: 'stimulus_snapshot_contract',
                backend: 'verilator',
                silent: true,
                options: { vendorPrepare: false },
            },
        );
        assert.strictEqual(response.success, true);
        assert.strictEqual(response.backend, 'verilator');
        await waitFor(
            'Verilator stimulus waveform panel',
            () => waveform.activePanelCount,
            count => count === 1,
            30_000,
        );

        const { default: puppeteer } = await import('puppeteer-core');
        const browser = await puppeteer.connect({
            browserURL: `http://127.0.0.1:${rendererPort}`,
        });
        let webview: WaveformSession | undefined;
        try {
            webview = await waitForWaveformSession(browser, '');
            const ports = await waitForWebviewState<{
                clk: string;
                rst: string;
                q: string;
                enabled: boolean;
            }>(webview, `(() => {
                const pinia = document.querySelector('#app')?.__vue_app__
                    ?.config?.globalProperties?.$pinia;
                const remote = pinia?._s?.get('remoteSimulator');
                const id = signal => [...signal.path, signal.name].join('.');
                const find = name => remote?.availableSignals.find(signal => signal.name === name);
                const clk = find('clk');
                const rst = find('rst');
                const q = find('q');
                const tab = document.querySelectorAll('.nav-icon-btn')[1];
                return {
                    clk: clk ? id(clk) : '',
                    rst: rst ? id(rst) : '',
                    q: q ? id(q) : '',
                    enabled: remote?.sessionCapabilities?.live_stimulus === true
                        && tab instanceof HTMLButtonElement
                        && !tab.disabled,
                };
            })()`, value => Boolean(value.clk && value.rst && value.q && value.enabled));

            await evaluateWebview<void>(webview, `(() => {
                const tab = document.querySelectorAll('.nav-icon-btn')[1];
                if (!(tab instanceof HTMLButtonElement) || tab.disabled) {
                    throw new Error('stimulus panel is unavailable');
                }
                tab.click();
                const pinia = document.querySelector('#app')?.__vue_app__
                    ?.config?.globalProperties?.$pinia;
                const simulate = pinia?._s?.get('simulate');
                if (!simulate) throw new Error('simulate store is unavailable');
                simulate.clkConfig.signalName = ${JSON.stringify(ports.clk)};
                simulate.clkConfig.frequency = 100;
                simulate.clkConfig.unit = 'MHz';
                simulate.rstConfig.signalName = '';
            })()`);
            await waitForWebviewState<boolean>(webview, `
                Boolean(document.querySelector('.simulate-panel .btn-apply:not(:disabled)'))
            `);
            await evaluateWebview<void>(webview, `(() => {
                const apply = document.querySelector('.simulate-panel .btn-apply');
                if (!(apply instanceof HTMLButtonElement) || apply.disabled) {
                    throw new Error('stimulus Apply button is unavailable');
                }
                apply.click();
            })()`);
            const sentAfterApply = await evaluateWebview<string[]>(webview, `
                globalThis.__digitalWaveformTestDiagnostics?.sent ?? []
            `);
            assert.ok(
                !sentAfterApply.some(message => message.includes('remoteReplaceSimulationConfiguration')),
                'Apply touched the simulator before a new run',
            );

            await evaluateWebview<void>(webview, `(async () => {
                const pinia = document.querySelector('#app')?.__vue_app__
                    ?.config?.globalProperties?.$pinia;
                const simulate = pinia?._s?.get('simulate');
                const wave = pinia?._s?.get('wave');
                if (!simulate || !wave) throw new Error('waveform stores are unavailable');
                simulate.clkConfig.signalName = ${JSON.stringify(ports.rst)};
                simulate.clkConfig.frequency = 25;
                await wave.addSignal(${JSON.stringify(ports.q)}, 'q', 1, 'stimulus_snapshot_contract');
            })()`);
            await clickWebviewToolbarButton(webview, 'restart');
            await waitForWebviewState<boolean>(webview, `(() => {
                const pinia = document.querySelector('#app')?.__vue_app__
                    ?.config?.globalProperties?.$pinia;
                const remote = pinia?._s?.get('remoteSimulator');
                return remote?.actualSimTimeNs === 0 && remote?.simulationStatus === 'connected';
            })()`);
            await clickWebviewToolbarButton(webview, 'start-fixed');
            await waitForRemoteRunState(webview, 50, true);

            const sent = await evaluateWebview<string[]>(webview, `
                globalThis.__digitalWaveformTestDiagnostics?.sent ?? []
            `);
            const messages = sent.flatMap(message => {
                try { return [JSON.parse(message)]; } catch { return []; }
            });
            const replaceIndex = messages.findIndex(message => (
                message.type === 'remoteReplaceSimulationConfiguration'
            ));
            const startIndex = messages.findIndex(message => (
                message.type === 'remoteStartSimWithConfig'
            ));
            assert.ok(replaceIndex >= 0, 'the applied snapshot was not published to the backend');
            assert.ok(startIndex > replaceIndex, 'the simulator started before snapshot publication');
            assert.strictEqual(messages[startIndex].clk_config.signal_name, ports.clk);
            assert.strictEqual(messages[startIndex].clk_config.frequency_hz, 100_000_000);
            assert.notStrictEqual(messages[startIndex].clk_config.signal_name, ports.rst);
            const snapshotState = await evaluateWebview<{
                pending: boolean;
                dirty: boolean;
            }>(webview, `(() => {
                const pinia = document.querySelector('#app')?.__vue_app__
                    ?.config?.globalProperties?.$pinia;
                const simulate = pinia?._s?.get('simulate');
                return {
                    pending: Boolean(simulate?.appliedConfigurationPending),
                    dirty: Boolean(simulate?.stimulusConfigurationDirty),
                };
            })()`);
            assert.deepStrictEqual(snapshotState, { pending: false, dirty: true });
        } finally {
            if (webview) await webview.session.detach();
            await browser.disconnect();
            await vscode.commands.executeCommand('workbench.action.closeActiveEditor');
            await waitFor(
                'Verilator stimulus waveform disposal',
                () => waveform.activePanelCount,
                count => count === 0,
            );
        }
    });

    test('drives ModelSim and Questa through the real interactive Waveform Webview', async function () {
        if (!process.env.DIDE_MODELSIM_BIN) {
            this.skip();
            return;
        }
        this.timeout(300_000);
        const rendererPort = process.env.DIGITAL_TEST_RENDERER_DEBUG_PORT;
        assert.ok(rendererPort, 'renderer debugging port is unavailable');
        const api = await activateExtension();
        const waveform = api.waveform;
        assert.ok(waveform, 'waveform extension API is unavailable');
        const source = workspaceUri('src/verilog/modelsim_wave_live.v');
        await vscode.workspace.fs.createDirectory(vscode.Uri.file(path.dirname(source.fsPath)));
        await vscode.workspace.fs.writeFile(source, Buffer.from(
            '`timescale 1ns/1ps\n'
            + 'module modelsim_wave_live;\n'
            + 'reg clk;\n'
            + 'reg q;\n'
            + 'initial begin clk = 1\'b0; q = 1\'b0; end\n'
            + 'always #5 clk = ~clk;\n'
            + 'always @(posedge clk) q <= ~q;\n'
            + 'endmodule\n',
        ));
        await vscode.commands.executeCommand('workbench.action.closeSidebar');
        await vscode.commands.executeCommand('workbench.action.closeAuxiliaryBar');
        await vscode.commands.executeCommand('workbench.action.closePanel');

        const { default: puppeteer } = await import('puppeteer-core');
        const browser = await puppeteer.connect({
            browserURL: `http://127.0.0.1:${rendererPort}`,
        });
        try {
            for (const backend of ['modelsim', 'questa'] as const) {
                let webview: WaveformSession | undefined;
                try {
                    const response = await vscode.commands.executeCommand<SimulationResponse>(
                        'digital-ide.tool.simulateFile',
                        {
                            fileUri: source,
                            moduleName: 'modelsim_wave_live',
                            backend,
                            silent: true,
                            options: { vendorPrepare: false },
                        },
                    );
                    assert.strictEqual(response.success, true);
                    assert.strictEqual(response.backend, backend);
                    assert.strictEqual(
                        response.simulationHome,
                        workspaceUri(`prj/simulation/${backend}/modelsim_wave_live`).fsPath,
                    );
                    assert.ok(response.artifacts.some(artifact => (
                        artifact.kind === 'executable'
                        && artifact.args?.includes('-pli')
                        && artifact.args?.includes('run -all')
                    )), `${backend} did not return its approved VPI launch specification`);
                    await waitFor(
                        `${backend} interactive waveform panel`,
                        () => waveform.activePanelCount,
                        count => count === 1,
                        30_000,
                    );

                    webview = await waitForWaveformSession(browser, '');
                    const injectControlExists = await evaluateWebview<boolean>(webview, `
                        document.body.innerText.includes('Inject Stimulus')
                            || Boolean(document.querySelector('img[alt="inject"]'))
                            || Array.from(document.querySelectorAll('button'))
                                .some(button => /inject stimulus/i.test(button.title))
                    `);
                    assert.strictEqual(
                        injectControlExists,
                        false,
                        'the removed Inject Stimulus toolbar control is still rendered',
                    );

                    await waitForWebviewState<boolean>(webview, `(() => {
                        const pinia = document.querySelector('#app')?.__vue_app__
                            ?.config?.globalProperties?.$pinia;
                        const remote = pinia?._s?.get('remoteSimulator');
                        return Boolean(remote?.simulatorConnected)
                            && remote.availableSignals.some(signal => signal.name === 'q');
                    })()`);
                    const stimulusGate = await evaluateWebview<{
                        liveStimulus: boolean;
                        panelDisabled: boolean;
                    }>(webview, `(() => {
                        const pinia = document.querySelector('#app')?.__vue_app__
                            ?.config?.globalProperties?.$pinia;
                        const remote = pinia?._s?.get('remoteSimulator');
                        const panel = document.querySelectorAll('.nav-icon-btn')[1];
                        return {
                            liveStimulus: remote?.sessionCapabilities?.live_stimulus === true,
                            panelDisabled: panel instanceof HTMLButtonElement && panel.disabled,
                        };
                    })()`);
                    assert.deepStrictEqual(
                        stimulusGate,
                        { liveStimulus: false, panelDisabled: true },
                        `${backend} exposed the unsupported external stimulus panel`,
                    );
                    await evaluateWebview<void>(webview, `(() => {
                        const root = Array.from(document.querySelectorAll('.node-label'))
                            .find(element => element.innerText.trim() === '(top)');
                        if (!root) throw new Error('remote hierarchy root is unavailable');
                        const expand = root.closest('.tree-node-row')?.querySelector('.expand-icon');
                        if (expand) expand.dispatchEvent(new MouseEvent('click', { bubbles: true }));
                    })()`);
                    await waitForWebviewState<boolean>(webview, `
                        Array.from(document.querySelectorAll('.node-label'))
                            .some(element => element.innerText.trim() === 'modelsim_wave_live')
                    `);
                    await evaluateWebview<void>(webview, `(() => {
                        const module = Array.from(document.querySelectorAll('.node-label'))
                            .find(element => element.innerText.trim() === 'modelsim_wave_live');
                        if (!module) throw new Error('modelsim_wave_live hierarchy node is unavailable');
                        module.dispatchEvent(new MouseEvent('click', { bubbles: true }));
                    })()`);
                    await waitForWebviewState<boolean>(webview, `
                        Array.from(document.querySelectorAll('.signal-list .signal-name'))
                            .some(element => element.innerText.trim() === 'q')
                    `);
                    await evaluateWebview<void>(webview, `(() => {
                        const signal = Array.from(
                            document.querySelectorAll('.signal-list .signal-name'),
                        ).find(element => element.innerText.trim() === 'q');
                        if (!signal) throw new Error('q signal is unavailable');
                        signal.dispatchEvent(new MouseEvent('dblclick', { bubbles: true }));
                    })()`);
                    await waitForWebviewState<boolean>(webview, `(() => {
                        const pinia = document.querySelector('#app')?.__vue_app__
                            ?.config?.globalProperties?.$pinia;
                        const wave = pinia?._s?.get('wave');
                        return wave?.tracks.some(track => track.variableId.endsWith('.q'));
                    })()`);

                    await clickWebviewToolbarButton(webview, 'restart');
                    await waitForWebviewState<RemoteRunState>(
                        webview,
                        remoteRunStateExpression(),
                        value => value.timeNs === 0
                            && value.status === 'connected'
                            && value.rangeEndNs === '0',
                    );
                    await clickWebviewToolbarButton(webview, 'start-fixed');
                    await waitForRemoteRunState(webview, 50, true);
                    await clickWebviewToolbarButton(webview, 'start-fixed');
                    await waitForRemoteRunState(webview, 100, true);

                    await clickWebviewToolbarButton(webview, 'restart');
                    const restarted = await waitForWebviewState<RemoteRunState>(
                        webview,
                        remoteRunStateExpression(),
                        value => value.timeNs === 0
                            && value.status === 'connected'
                            && value.rangeEndNs === '0',
                    );
                    assert.strictEqual(restarted.error, null);

                    await clickWebviewToolbarButton(webview, 'start-fixed');
                    await waitForRemoteRunState(webview, 50, true);
                    assert.ok(
                        webview.diagnostics.receivedFrames.some(frame => frame.startsWith('2:')),
                        `${backend} did not stream a binary WTD2 frame into the Webview`,
                    );

                    const workbench = (await browser.pages()).find(page => page.url().includes('workbench'));
                    assert.ok(workbench, 'VS Code workbench page is unavailable');
                    const waveformPixels = await waitForWorkbenchBitPixels(workbench, webview);
                    assert.ok(
                        waveformPixels > 100,
                        `${backend} waveform track was not rendered into the VS Code workbench`,
                    );
                } finally {
                    if (webview) await webview.session.detach();
                    await vscode.commands.executeCommand('workbench.action.closeActiveEditor');
                    await waitFor(
                        `${backend} interactive waveform disposal`,
                        () => waveform.activePanelCount,
                        count => count === 0,
                        30_000,
                    );
                }
            }
        } finally {
            await browser.disconnect();
        }
    });

    for (const fixture of [
        ['vcd', 'tests/wave/wikipedia/example.vcd'],
        ['fst', 'tests/wave/verilator/basic_test.fst'],
        ['ghw', 'tests/wave/ghdl/issue_32.ghw'],
    ] as const) {
        test(`opens a parsed ${fixture[0].toUpperCase()} from Explorer`, async function () {
            this.timeout(120_000);
            const api = await activateExtension();
            const waveform = api.waveform;
            assert.ok(waveform, 'waveform extension API is unavailable');
            const source = path.join(serverRoot, fixture[1]);
            assert.ok(fs.existsSync(source), `missing waveform fixture: ${source}`);
            const target = workspaceUri(`waveform/example.${fixture[0]}`);
            await vscode.workspace.fs.createDirectory(vscode.Uri.file(path.dirname(target.fsPath)));
            await vscode.workspace.fs.writeFile(target, fs.readFileSync(source));
            await vscode.commands.executeCommand(
                'vscode.openWith',
                target,
                'digital-ide.waveformViewer',
                { preview: false },
            );
            const active = vscode.window.tabGroups.activeTabGroup.activeTab;
            assert.ok(active, `${fixture[0]} did not open an editor tab`);
            assert.strictEqual(active.label, 'DIDE-WAVE');
            await waitFor(
                `${fixture[0]} waveform Webview ready handshake`,
                () => waveform.activePanelCount,
                count => count === 1,
                30_000,
            );
            await vscode.commands.executeCommand('workbench.action.closeActiveEditor');
            await waitFor(
                `${fixture[0]} waveform Webview disposal`,
                () => waveform.activePanelCount,
                count => count === 0,
            );
        });
    }

    test('rejects an invalid waveform instead of opening an empty renderer', async function () {
        this.timeout(30_000);
        const api = await activateExtension();
        const waveform = api.waveform;
        assert.ok(waveform, 'waveform extension API is unavailable');
        const invalid = workspaceUri('waveform/invalid.vcd');
        await vscode.workspace.fs.writeFile(invalid, Buffer.from('not a waveform\n'));
        const panel = vscode.window.createWebviewPanel(
            'digital-ide.waveformViewer',
            'Invalid Waveform',
            vscode.ViewColumn.Active,
            { enableScripts: true },
        );
        await assert.rejects(
            waveform.resolveFile(invalid, panel),
            /waveform|parse|load|format/i,
        );
        assert.strictEqual(waveform.activePanelCount, 0);
        assert.throws(() => panel.visible, /disposed/i);
    });

    test('closes managed Webviews when the waveform manager is disposed', async function () {
        this.timeout(60_000);
        const api = await activateExtension();
        const waveform = api.waveform;
        assert.ok(waveform, 'waveform extension API is unavailable');
        const capture = await waveform.openCapture(
            {
                vendor: 'vivado',
                coreId: 4,
                coreLabel: 'dispose_contract_ila',
                dataDepth: 16,
                probes: [{ name: 'counter', width: 4 }],
                triggerCondition: 'counter == 15',
                triggerEditable: true,
                triggerPosition: 8,
            },
            async () => undefined,
            'Waveform Dispose Contract',
        );
        assert.strictEqual(waveform.activePanelCount, 1);

        waveform.dispose();

        assert.strictEqual(waveform.activePanelCount, 0);
        assert.throws(() => capture.panel.visible, /disposed/i);
    });

    test('builds VCS in Docker and drives it through the real Waveform Webview', async function () {
        if (!process.env.DIDE_VCS_DOCKER_CONTAINER) {
            this.skip();
            return;
        }
        this.timeout(600_000);
        const rendererPort = process.env.DIGITAL_TEST_RENDERER_DEBUG_PORT;
        assert.ok(rendererPort, 'renderer debugging port is unavailable');
        const api = await activateExtension();
        const waveform = api.waveform;
        assert.ok(waveform, 'waveform extension API is unavailable');
        const source = workspaceUri('src/verilog/vcs_wave_live.v');
        await vscode.workspace.fs.createDirectory(vscode.Uri.file(path.dirname(source.fsPath)));
        await vscode.workspace.fs.writeFile(source, Buffer.from(
            '`timescale 1ns/1ps\n'
            + 'module vcs_wave_live;\n'
            + 'reg clk;\n'
            + 'reg q;\n'
            + 'initial begin clk = 1\'b0; q = 1\'b0; end\n'
            + 'always #5 clk = ~clk;\n'
            + 'always @(posedge clk) q <= ~q;\n'
            + 'endmodule\n',
        ));

        const simulationHome = workspaceUri('prj/simulation/vcs/vcs_wave_live').fsPath;
        const toolDirectory = path.join(simulationHome, 'docker-tools');
        fs.mkdirSync(toolDirectory, { recursive: true });
        const scriptDirectory = path.join(serverRoot, 'tests', '0.5.x', 'scripts');
        const toolSource = path.join(scriptDirectory, 'vcs-docker-tool.js');
        const toolPaths = Object.fromEntries(['cxx', 'vcs', 'vhdlan', 'vlogan'].map(name => {
            const target = path.join(toolDirectory, name);
            fs.copyFileSync(toolSource, target);
            fs.chmodSync(target, 0o755);
            return [name, target];
        })) as Record<'cxx' | 'vcs' | 'vhdlan' | 'vlogan', string>;
        const launchPath = path.join(simulationHome, 'vcs-docker-launch');
        fs.copyFileSync(path.join(scriptDirectory, 'vcs-docker-launch.js'), launchPath);
        fs.chmodSync(launchPath, 0o755);

        await vscode.commands.executeCommand('workbench.action.closeSidebar');
        await vscode.commands.executeCommand('workbench.action.closeAuxiliaryBar');
        await vscode.commands.executeCommand('workbench.action.closePanel');

        const { default: puppeteer } = await import('puppeteer-core');
        const browser = await puppeteer.connect({
            browserURL: `http://127.0.0.1:${rendererPort}`,
        });
        let webview: WaveformSession | undefined;
        try {
            const response = await vscode.commands.executeCommand<SimulationResponse>(
                'digital-ide.tool.simulateFile',
                {
                    fileUri: source,
                    moduleName: 'vcs_wave_live',
                    backend: 'vcs',
                    silent: true,
                    options: {
                        vlogan_path: toolPaths.vlogan,
                        vhdlan_path: toolPaths.vhdlan,
                        vcs_path: toolPaths.vcs,
                        cxx_path: toolPaths.cxx,
                        launch_path: launchPath,
                        incremental: false,
                        server_harness: {
                            server_cpp: 'managed-by-digital-server',
                            extra_cflags: ['-DVCS_REMOTE_BIND_ANY'],
                        },
                    },
                },
            );
            assert.strictEqual(response.success, true);
            assert.strictEqual(response.backend, 'vcs');
            assert.strictEqual(response.simulationHome, simulationHome);
            assert.ok(
                response.artifacts.some(artifact => (
                    artifact.kind === 'executable' && artifact.path === launchPath
                )),
                'VCS did not return the approved Docker launch executable',
            );
            const builtExecutable = response.report?.executable_file;
            assert.strictEqual(typeof builtExecutable, 'string');
            assert.ok(
                path.resolve(builtExecutable as string).startsWith(`${path.resolve(simulationHome)}${path.sep}`),
                `VCS executable escaped prj/simulation: ${builtExecutable}`,
            );
            assert.ok(fs.existsSync(builtExecutable as string), 'VCS executable was not built');

            await waitFor(
                'VCS interactive waveform panel',
                () => waveform.activePanelCount,
                count => count === 1,
                30_000,
            );
            webview = await waitForWaveformSession(browser, '');
            await waitForWebviewState<boolean>(webview, `(() => {
                const pinia = document.querySelector('#app')?.__vue_app__
                    ?.config?.globalProperties?.$pinia;
                const remote = pinia?._s?.get('remoteSimulator');
                return Boolean(remote?.simulatorConnected)
                    && remote?.sessionCapabilities?.live_stimulus === true
                    && remote.availableSignals.some(signal => signal.name === 'q');
            })()`);
            const stimulusPanelDisabled = await evaluateWebview<boolean>(webview, `(() => {
                const panel = document.querySelectorAll('.nav-icon-btn')[1];
                return panel instanceof HTMLButtonElement && panel.disabled;
            })()`);
            assert.strictEqual(stimulusPanelDisabled, false, 'VCS stimulus configuration is disabled');
            await evaluateWebview<void>(webview, `(() => {
                const root = Array.from(document.querySelectorAll('.node-label'))
                    .find(element => element.innerText.trim() === '(top)');
                if (!root) throw new Error('remote hierarchy root is unavailable');
                const expand = root.closest('.tree-node-row')?.querySelector('.expand-icon');
                if (expand) expand.dispatchEvent(new MouseEvent('click', { bubbles: true }));
            })()`);
            await waitForWebviewState<boolean>(webview, `
                Array.from(document.querySelectorAll('.node-label'))
                    .some(element => element.innerText.trim() === 'vcs_wave_live')
            `);
            await evaluateWebview<void>(webview, `(() => {
                const module = Array.from(document.querySelectorAll('.node-label'))
                    .find(element => element.innerText.trim() === 'vcs_wave_live');
                if (!module) throw new Error('vcs_wave_live hierarchy node is unavailable');
                module.dispatchEvent(new MouseEvent('click', { bubbles: true }));
            })()`);
            await waitForWebviewState<boolean>(webview, `
                Array.from(document.querySelectorAll('.signal-list .signal-name'))
                    .some(element => element.innerText.trim() === 'q')
            `);
            await evaluateWebview<void>(webview, `(() => {
                const signal = Array.from(document.querySelectorAll('.signal-list .signal-name'))
                    .find(element => element.innerText.trim() === 'q');
                if (!signal) throw new Error('q signal is unavailable');
                signal.dispatchEvent(new MouseEvent('dblclick', { bubbles: true }));
            })()`);
            await waitForWebviewState<boolean>(webview, `(() => {
                const pinia = document.querySelector('#app')?.__vue_app__
                    ?.config?.globalProperties?.$pinia;
                const wave = pinia?._s?.get('wave');
                return wave?.tracks.some(track => track.variableId.endsWith('.q'));
            })()`);

            await clickWebviewToolbarButton(webview, 'restart');
            await waitForWebviewState<RemoteRunState>(
                webview,
                remoteRunStateExpression(),
                value => value.timeNs === 0
                    && value.status === 'connected'
                    && value.rangeEndNs === '0',
            );
            await clickWebviewToolbarButton(webview, 'start-fixed');
            await waitForRemoteRunState(webview, 50, true);
            await clickWebviewToolbarButton(webview, 'start-fixed');
            await waitForRemoteRunState(webview, 100, true);
            await clickWebviewToolbarButton(webview, 'restart');
            await waitForWebviewState<RemoteRunState>(
                webview,
                remoteRunStateExpression(),
                value => value.timeNs === 0
                    && value.status === 'connected'
                    && value.rangeEndNs === '0',
            );
            await clickWebviewToolbarButton(webview, 'start-fixed');
            await waitForRemoteRunState(webview, 50, true);
            assert.ok(
                webview.diagnostics.receivedFrames.some(frame => frame.startsWith('2:')),
                'VCS did not stream a binary WTD2 frame into the Webview',
            );
            const workbench = (await browser.pages()).find(page => page.url().includes('workbench'));
            assert.ok(workbench, 'VS Code workbench page is unavailable');
            assert.ok(
                await waitForWorkbenchBitPixels(workbench, webview) > 100,
                'VCS waveform track was not rendered into the VS Code workbench',
            );
        } finally {
            if (webview) await webview.session.detach();
            await browser.disconnect();
            await vscode.commands.executeCommand('workbench.action.closeActiveEditor');
            await waitFor(
                'VCS interactive waveform disposal',
                () => waveform.activePanelCount,
                count => count === 0,
                30_000,
            );
        }
    });

    test('connects a VCS executable to the waveform Webview', async function () {
        this.timeout(180_000);
        const executable = process.env.DIGITAL_TEST_VCS_EXECUTABLE;
        if (!executable) {
            this.skip();
            return;
        }
        assert.ok(fs.existsSync(executable), `missing VCS simulator fixture: ${executable}`);
        const api = await activateExtension();
        const waveform = api.waveform;
        assert.ok(waveform, 'waveform extension API is unavailable');

        await waveform.openSimulator('vcs', executable, 'vcs_contract (VCS)');
        assert.strictEqual(waveform.activePanelCount, 1);
        assert.strictEqual(
            vscode.window.tabGroups.activeTabGroup.activeTab?.label,
            'vcs_contract (VCS)',
        );
        await vscode.commands.executeCommand('workbench.action.closeActiveEditor');
        await waitFor(
            'VCS waveform Webview disposal',
            () => waveform.activePanelCount,
            count => count === 0,
        );
    });
});

async function waitForWaveformSession(
    browser: Browser,
    expectedText: string,
): Promise<WaveformSession> {
    const deadline = Date.now() + 30_000;
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
            session.on('Runtime.executionContextCreated', event => {
                contexts.push(event.context);
            });
            try {
                await session.send('Runtime.enable');
                await session.send('Page.enable');
                const frameTree = await session.send('Page.getFrameTree');
                for (const frameId of collectFrameIds(frameTree.frameTree)) {
                    const frameContexts = contexts.filter(context => (
                        context.auxData?.frameId === frameId && context.auxData.isDefault
                    ));
                    for (const context of frameContexts) {
                        const candidate = {
                            session,
                            contextId: context.id,
                            diagnostics: createWebviewDiagnostics(session),
                        };
                        const matches = await evaluateWebview<boolean>(candidate, `
                            Boolean(document.querySelector('.app-container'))
                                && document.body?.innerText.includes(${JSON.stringify(expectedText)})
                        `);
                        if (matches) {
                            await evaluateWebview<void>(candidate, `(() => {
                                const diagnostics = { sent: [] };
                                const originalSend = WebSocket.prototype.send;
                                WebSocket.prototype.send = function(data) {
                                    diagnostics.sent.push(
                                        typeof data === 'string'
                                            ? data.slice(0, 500)
                                            : Object.prototype.toString.call(data)
                                    );
                                    return originalSend.call(this, data);
                                };
                                globalThis.__digitalWaveformTestDiagnostics = diagnostics;
                            })()`);
                            return candidate;
                        }
                    }
                }
            } catch {
                // A Webview target can be replaced while VS Code commits the custom editor.
            }
            await session.detach();
        }
        await new Promise(resolve => setTimeout(resolve, 100));
    }
    const targets = browser.targets().map(target => ({
        type: target.type(),
        url: target.url(),
    }));
    throw new Error(
        `timed out waiting for VS Code Webview target containing ${expectedText}; `
        + `targets=${JSON.stringify(targets)}`,
    );
}

interface WaveformSession {
    session: CDPSession;
    contextId: number;
    diagnostics: WebviewDiagnostics;
}

interface WebviewDiagnostics {
    console: string[];
    sentFrames: string[];
    receivedFrames: string[];
}

interface WaveformPixelStats {
    width: number;
    height: number;
    parameterPixels: number;
    clockPixels: number;
}

interface RemoteRunState {
    timeNs: number;
    status: string;
    rangeEndNs: string;
    hasRenderFrame: boolean;
    error: string | null;
}

interface CaptureDisplayState {
    captureName: string;
    tracks: Array<{
        id: string;
        variableId: string;
        name: string;
        path: string;
        format: string;
        color: string;
        height: number;
        width: number;
        groupId: string | null;
        varType: string | null;
        isAnalog: boolean;
        analogMode: string | null;
    }>;
    selectedTrackIds: string[];
    groups: Array<{
        id: string;
        name: string;
        isOpen: boolean;
        content: string[];
    }>;
    displayedItemTree: Array<{
        itemId: string;
        level: number;
        unfolded: boolean;
        selected: boolean;
    }>;
    compareSourceId: string | null;
    renderGeneration: number;
    renderSignature: string[];
}

interface WebviewFrameTree {
    frame: { id: string };
    childFrames?: WebviewFrameTree[];
}

function captureDisplayStateExpression(): string {
    return `(() => {
        const pinia = document.querySelector('#app')?.__vue_app__
            ?.config?.globalProperties?.$pinia;
        const wave = pinia?._s?.get('wave');
        const frame = wave?.latestRenderFrame;
        const renderSignature = (frame?.tracks ?? []).map(track => {
            if (track.type === 'bit') {
                return 'bit:' + track.initialHigh + ':'
                    + Array.from(track.xPositions).join(',') + ':'
                    + Array.from(track.densePixels).join(',');
            }
            if (track.type === 'bus') {
                return 'bus:' + track.segments
                    .map(segment => [segment.xStart, segment.xEnd, segment.value, segment.isDense].join(':'))
                    .join(',');
            }
            if (track.type === 'analog') {
                return 'analog:' + [track.globalMin, track.globalMax].join(':') + ':'
                    + Array.from(track.flatStartVal).join(',') + ':'
                    + Array.from(track.flatEndVal).join(',') + ':'
                    + Array.from(track.rangeMinVal).join(',') + ':'
                    + Array.from(track.rangeMaxVal).join(',');
            }
            return 'error:' + track.message;
        });
        return {
            captureName: wave?.activeCaptureName ?? '',
            tracks: (wave?.tracks ?? []).map(track => ({
                id: track.id,
                variableId: track.variableId,
                name: track.name,
                path: track.path,
                format: track.format,
                color: track.color,
                height: track.height,
                width: track.width,
                groupId: track.groupId ?? null,
                varType: track.varType ?? null,
                isAnalog: Boolean(track.isAnalog),
                analogMode: track.analogMode ?? null,
            })),
            selectedTrackIds: Array.from(wave?.selectedTrackIds ?? []).sort(),
            groups: Array.from(wave?.groups?.values?.() ?? []).map(group => ({
                id: group.id,
                name: group.name,
                isOpen: group.isOpen,
                content: [...group.content],
            })),
            displayedItemTree: (wave?.displayedItemTree ?? []).map(node => ({ ...node })),
            compareSourceId: wave?.compareSourceId ?? null,
            renderGeneration: frame?.generation ?? 0,
            renderSignature,
        };
    })()`;
}

async function publishTestHardwareCapture(
    waveformUrl: string,
    name: string,
    sample: (index: number) => { counter: number; valid: number },
): Promise<void> {
    const samples = Array.from({ length: 64 }, (_, index) => {
        const value = sample(index);
        const counterBits = Array.from(
            { length: 4 },
            (__, bit) => ((value.counter >>> bit) & 1).toString(),
        ).join('');
        const validBit = value.valid ? '1' : '0';
        return {
            index,
            time: index,
            values: [
                { name: 'ila.counter', bits: `0b${counterBits}`, display: String(value.counter) },
                { name: 'ila.valid', bits: `0b${validBit}`, display: validBit },
            ],
        };
    });
    const request = {
        type: 'loadCapture',
        name,
        capture: {
            schema: {
                sample_width: 5,
                signals: [
                    { name: 'ila.counter', offset: 0, width: 4, radix: 'unsigned' },
                    { name: 'ila.valid', offset: 4, width: 1, radix: 'binary' },
                ],
                sample_order: 'first-shifted-first',
                sample_period: 1,
                timescale: '1ns',
            },
            samples,
        },
    };

    await new Promise<void>((resolve, reject) => {
        const socket = new WebSocket(waveformUrl);
        let complete = false;
        const timer = setTimeout(() => finish(new Error(`Timed out publishing capture ${name}`)), 15_000);
        const finish = (error?: Error): void => {
            if (complete) return;
            complete = true;
            clearTimeout(timer);
            if (socket.readyState === WebSocket.OPEN) socket.close();
            if (error) reject(error);
            else resolve();
        };
        socket.once('open', () => socket.send(JSON.stringify(request)));
        socket.on('message', payload => {
            try {
                const response = JSON.parse(payload.toString()) as {
                    type?: string;
                    code?: string;
                    message?: string;
                };
                if (response.type === 'capturePublished') finish();
                if (response.type === 'error') {
                    finish(new Error(`${response.code ?? 'CAPTURE_ERROR'}: ${response.message ?? ''}`));
                }
            } catch (error) {
                finish(error instanceof Error ? error : new Error(String(error)));
            }
        });
        socket.once('error', error => finish(error));
    });
}

function collectFrameIds(tree: WebviewFrameTree): string[] {
    const ids = [tree.frame.id];
    for (const child of tree.childFrames ?? []) ids.push(...collectFrameIds(child));
    return ids;
}

function createWebviewDiagnostics(session: CDPSession): WebviewDiagnostics {
    const diagnostics: WebviewDiagnostics = {
        console: [],
        sentFrames: [],
        receivedFrames: [],
    };
    session.on('Runtime.consoleAPICalled', event => {
        diagnostics.console.push(
            `${event.type}: ${event.args.map((argument: { value?: unknown; description?: string }) => (
                argument.value === undefined ? argument.description : String(argument.value)
            )).join(' ')}`,
        );
    });
    session.on('Runtime.exceptionThrown', event => {
        diagnostics.console.push(
            `exception: ${event.exceptionDetails.exception?.description ?? event.exceptionDetails.text}`,
        );
    });
    session.on('Network.webSocketFrameSent', event => {
        diagnostics.sentFrames.push(
            `${event.response.opcode}:${event.response.payloadData.slice(0, 500)}`,
        );
    });
    session.on('Network.webSocketFrameReceived', event => {
        diagnostics.receivedFrames.push(
            `${event.response.opcode}:${event.response.payloadData.slice(0, 500)}`,
        );
    });
    void session.send('Network.enable');
    return diagnostics;
}

async function waitForWorkbenchEditorChrome(
    workbench: Page,
    expectedTabTitle: string,
    expectedBreadcrumb: string,
): Promise<void> {
    await workbench.waitForFunction((tabTitle, breadcrumb) => {
        const activeTab = document.querySelector('.tabs-container .tab.active');
        const activeTabText = activeTab?.querySelector('.label-name')?.textContent
            ?? activeTab?.textContent
            ?? '';
        const breadcrumbText = document.querySelector('.breadcrumbs-control')?.textContent ?? '';
        return activeTabText.includes(String(tabTitle))
            && breadcrumbText.includes(String(breadcrumb));
    }, { timeout: 30_000 }, expectedTabTitle, expectedBreadcrumb);
}

async function assertGlobalFocusRingsSuppressed(webview: WaveformSession): Promise<void> {
    const selectors = [
        '.icon-btn',
        '.signal-container',
        '.run-time-value',
        '.search-input',
    ];
    for (const selector of selectors) {
        await evaluateWebview<void>(webview, `(() => {
            const element = document.querySelector(${JSON.stringify(selector)});
            if (!(element instanceof HTMLElement)) {
                throw new Error(${JSON.stringify(`global focus regression target is unavailable: ${selector}`)});
            }
            element.focus();
            if (document.activeElement !== element) {
                throw new Error(${JSON.stringify(`global focus regression target cannot be focused: ${selector}`)});
            }
        })()`);
        await webview.session.send('Input.dispatchKeyEvent', {
            type: 'keyDown',
            key: 'Shift',
            code: 'ShiftLeft',
            windowsVirtualKeyCode: 16,
            nativeVirtualKeyCode: 16,
            modifiers: 8,
        });
        const focusStyle = await evaluateWebview<{
            outlineStyle: string;
            outlineWidth: string;
            boxShadow: string;
        }>(webview, `(() => {
            const element = document.querySelector(${JSON.stringify(selector)});
            if (!(element instanceof HTMLElement)) {
                throw new Error(${JSON.stringify(`global focus regression target disappeared: ${selector}`)});
            }
            const style = getComputedStyle(element);
            return {
                outlineStyle: style.outlineStyle,
                outlineWidth: style.outlineWidth,
                boxShadow: style.boxShadow,
            };
        })()`);
        await webview.session.send('Input.dispatchKeyEvent', {
            type: 'keyUp',
            key: 'Shift',
            code: 'ShiftLeft',
            windowsVirtualKeyCode: 16,
            nativeVirtualKeyCode: 16,
        });
        assert.strictEqual(focusStyle.outlineStyle, 'none', selector);
        assert.strictEqual(focusStyle.outlineWidth, '0px', selector);
        assert.strictEqual(focusStyle.boxShadow, 'none', selector);
    }
    await evaluateWebview<void>(webview, 'document.activeElement?.blur()');
}

async function selectWaveformThroughWorkbenchDialog(
    webview: WaveformSession,
    workbench: Page,
    filePath: string,
): Promise<void> {
    await evaluateWebview<void>(webview, `(() => {
        const fileButton = document.querySelector('img[alt="file"]')?.closest('button');
        if (!fileButton) throw new Error('waveform file toolbar button is unavailable');
        fileButton.click();
    })()`);
    await waitForWebviewState<boolean>(webview, `
        Boolean(document.querySelector('.file-dropdown-item'))
    `);
    await evaluateWebview<void>(webview, `(() => {
        const openWaveform = document.querySelector('.file-dropdown-item');
        if (!openWaveform) throw new Error('open waveform menu item is unavailable');
        openWaveform.dispatchEvent(new MouseEvent('click', { bubbles: true }));
    })()`);
    await workbench.bringToFront();
    await workbench.waitForFunction(() => {
        const widget = document.querySelector('.quick-input-widget');
        return Boolean(widget
            && getComputedStyle(widget).display !== 'none'
            && widget.textContent?.includes('Open Waveform File'));
    }, { timeout: 10_000 });

    const input = await workbench.$('.quick-input-widget input');
    assert.ok(input, 'VS Code waveform file dialog input is unavailable');
    await input.click({ clickCount: 3 });
    await workbench.keyboard.down('Control');
    await workbench.keyboard.press('A');
    await workbench.keyboard.up('Control');
    await input.type(filePath);
    await workbench.waitForFunction(() => {
        const widget = document.querySelector('.quick-input-widget');
        if (!widget) return false;
        return Array.from(widget.querySelectorAll('.monaco-button')).some(button => {
            const label = button.textContent?.trim() ?? '';
            return !/show local/i.test(label)
                && button.getAttribute('aria-disabled') !== 'true'
                && !button.classList.contains('disabled');
        });
    }, { timeout: 10_000 });
    await workbench.evaluate(() => {
        const widget = document.querySelector('.quick-input-widget');
        const button = Array.from(widget?.querySelectorAll('.monaco-button') ?? []).find(candidate => {
            const label = candidate.textContent?.trim() ?? '';
            return !/show local/i.test(label)
                && candidate.getAttribute('aria-disabled') !== 'true'
                && !candidate.classList.contains('disabled');
        });
        if (!(button instanceof HTMLElement)) throw new Error('VS Code file dialog confirm button is unavailable');
        button.click();
    });
    await workbench.waitForFunction(() => {
        const widget = document.querySelector('.quick-input-widget');
        return !widget || getComputedStyle(widget).display === 'none';
    }, { timeout: 10_000 });
}

async function waitForWorkbenchWaveformPixels(
    workbench: Page,
    webview: WaveformSession,
): Promise<WaveformPixelStats> {
    const deadline = Date.now() + 30_000;
    let stats: WaveformPixelStats = {
        width: 0,
        height: 0,
        parameterPixels: 0,
        clockPixels: 0,
    };
    while (Date.now() < deadline) {
        const screenshot = Buffer.from(await workbench.screenshot());
        const encoded = screenshot.toString('base64');
        stats = await evaluateWebview<WaveformPixelStats>(webview, `(async () => {
            const image = new Image();
            image.src = 'data:image/png;base64,' + ${JSON.stringify(encoded)};
            await image.decode();
            const canvas = document.createElement('canvas');
            canvas.width = image.width;
            canvas.height = image.height;
            const context = canvas.getContext('2d', { willReadFrequently: true });
            if (!context) throw new Error('2D screenshot decoder is unavailable');
            context.drawImage(image, 0, 0);
            const pixels = context.getImageData(0, 0, canvas.width, canvas.height).data;
            let parameterPixels = 0;
            let clockPixels = 0;
            for (let index = 0; index < pixels.length; index += 4) {
                const red = pixels[index];
                const green = pixels[index + 1];
                const blue = pixels[index + 2];
                if (Math.abs(red - 78) < 25
                    && Math.abs(green - 201) < 25
                    && Math.abs(blue - 176) < 25) {
                    parameterPixels += 1;
                }
                if (Math.abs(red - 220) < 25
                    && Math.abs(green - 220) < 25
                    && Math.abs(blue - 170) < 25) {
                    clockPixels += 1;
                }
            }
            return { width: canvas.width, height: canvas.height, parameterPixels, clockPixels };
        })()`);
        if (stats.parameterPixels > 5 && stats.clockPixels > 100) {
            fs.writeFileSync('/tmp/digital-vscode-workbench-waveform.png', screenshot);
            return stats;
        }
        await new Promise(resolve => setTimeout(resolve, 100));
    }
    throw new Error(
        `timed out waiting for composed WebGL waveform pixels: ${JSON.stringify(stats)}; `
        + `diagnostics=${JSON.stringify(webview.diagnostics)}`,
    );
}

async function waitForWorkbenchBitPixels(
    workbench: Page,
    webview: WaveformSession,
): Promise<number> {
    const deadline = Date.now() + 30_000;
    let bitPixels = 0;
    while (Date.now() < deadline) {
        const screenshot = Buffer.from(await workbench.screenshot());
        const encoded = screenshot.toString('base64');
        bitPixels = await evaluateWebview<number>(webview, `(async () => {
            const image = new Image();
            image.src = 'data:image/png;base64,' + ${JSON.stringify(encoded)};
            await image.decode();
            const canvas = document.createElement('canvas');
            canvas.width = image.width;
            canvas.height = image.height;
            const context = canvas.getContext('2d', { willReadFrequently: true });
            if (!context) throw new Error('2D screenshot decoder is unavailable');
            context.drawImage(image, 0, 0);
            const pixels = context.getImageData(0, 0, canvas.width, canvas.height).data;
            let count = 0;
            for (let index = 0; index < pixels.length; index += 4) {
                const red = pixels[index];
                const green = pixels[index + 1];
                const blue = pixels[index + 2];
                if (Math.abs(red - 78) < 25
                    && Math.abs(green - 201) < 25
                    && Math.abs(blue - 176) < 25) {
                    count += 1;
                }
            }
            return count;
        })()`);
        if (bitPixels > 100) return bitPixels;
        await new Promise(resolve => setTimeout(resolve, 100));
    }
    throw new Error(
        `timed out waiting for rendered interactive waveform pixels: ${bitPixels}; `
        + `diagnostics=${JSON.stringify(webview.diagnostics)}`,
    );
}

async function clickWebviewToolbarButton(
    webview: WaveformSession,
    imageAlt: string,
): Promise<void> {
    await evaluateWebview<void>(webview, `(() => {
        const image = document.querySelector(${JSON.stringify(`img[alt="${imageAlt}"]`)});
        const button = image?.closest('button');
        if (!button) throw new Error(${JSON.stringify(`${imageAlt} toolbar button is unavailable`)});
        if (button.disabled) throw new Error(${JSON.stringify(`${imageAlt} toolbar button is disabled`)});
        button.click();
    })()`);
}

function remoteRunStateExpression(): string {
    return `(() => {
        const pinia = document.querySelector('#app')?.__vue_app__
            ?.config?.globalProperties?.$pinia;
        const remote = pinia?._s?.get('remoteSimulator');
        const wave = pinia?._s?.get('wave');
        return {
            timeNs: remote?.actualSimTimeNs ?? -1,
            status: remote?.simulationStatus ?? 'missing',
            rangeEndNs: String(wave?.timeRangeEnd ?? -1),
            hasRenderFrame: Boolean(wave?.latestRenderFrame?.tracks?.length),
            error: remote?.simulationError ?? remote?.remoteStreamError ?? null,
        };
    })()`;
}

async function waitForRemoteRunState(
    webview: WaveformSession,
    expectedTimeNs: number,
    requireFrame: boolean,
): Promise<RemoteRunState> {
    const state = await waitForWebviewState<RemoteRunState>(
        webview,
        remoteRunStateExpression(),
        value => value.timeNs === expectedTimeNs
            && value.status === 'completed'
            && value.rangeEndNs === String(expectedTimeNs)
            && (!requireFrame || value.hasRenderFrame),
    );
    assert.strictEqual(state.error, null);
    return state;
}

async function evaluateWebview<T>(webview: WaveformSession, expression: string): Promise<T> {
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
            ?? 'Webview evaluation failed',
        );
    }
    return response.result.value as T;
}

async function waitForWebviewState<T>(
    webview: WaveformSession,
    expression: string,
    predicate: (value: T) => boolean = value => Boolean(value),
): Promise<T> {
    const deadline = Date.now() + 30_000;
    let value = await evaluateWebview<T>(webview, expression);
    while (!predicate(value)) {
        if (Date.now() >= deadline) {
            const runtimeDiagnostics = await evaluateWebview<unknown>(webview, `
                (() => {
                    const app = document.querySelector('#app')?.__vue_app__;
                    const pinia = app?.config?.globalProperties?.$pinia;
                    const store = pinia?._s?.get('wave');
                    const waveformCanvas = document.querySelector('.waveform-canvas');
                    return {
                        socket: globalThis.__digitalWaveformTestDiagnostics ?? null,
                        waveformCanvas: waveformCanvas ? {
                            clientWidth: waveformCanvas.clientWidth,
                            clientHeight: waveformCanvas.clientHeight,
                            rendererState: waveformCanvas.dataset.rendererState,
                            rendererBackend: waveformCanvas.dataset.rendererBackend,
                            rendererError: waveformCanvas.dataset.rendererError,
                        } : null,
                        canvases: Array.from(document.querySelectorAll('canvas')).map(canvas => ({
                            className: canvas.className,
                            clientWidth: canvas.clientWidth,
                            clientHeight: canvas.clientHeight,
                            width: canvas.width,
                            height: canvas.height,
                        })),
                        store: store ? {
                            connected: store.connected,
                            tracks: store.tracks.map(track => ({
                                name: track.name,
                                variableId: track.variableId,
                                format: track.format,
                                width: track.width,
                            })),
                            displayedItemTree: store.displayedItemTree,
                            viewportStart: String(store.viewportStart),
                            viewportEnd: String(store.viewportEnd),
                            cursorTime: String(store.cursorTime),
                            canvasWidth: store.canvasWidth,
                            latestRenderFrame: store.latestRenderFrame,
                        } : null,
                    };
                })()
            `);
            throw new Error(
                `timed out waiting for Webview state: ${JSON.stringify(value)}; `
                + `diagnostics=${JSON.stringify({
                    ...webview.diagnostics,
                    runtime: runtimeDiagnostics,
                })}`,
            );
        }
        await new Promise(resolve => setTimeout(resolve, 100));
        value = await evaluateWebview<T>(webview, expression);
    }
    return value;
}
