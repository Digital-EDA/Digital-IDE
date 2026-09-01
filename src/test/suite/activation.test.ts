import * as assert from 'assert';
import * as fs from 'fs';
import * as path from 'path';
import * as vscode from 'vscode';
import type { DigitalIdeExtensionApi } from '../../extension';
import {
    classifyLogLevel,
    DebuggerOutput,
    HardwareErrorOutput,
    HardwareOutput,
    LinterOutput,
    MainOutput,
    Output,
    ReportType,
    WaveOutput,
    WaveViewOutput,
    YosysOutput,
    hardwareOutputChannel,
    mainOutputChannel,
    outputChannels,
    serverOutputChannel,
    waveOutputChannel,
} from '../../global/outputs';
import { activateExtension } from './helpers';

suite('Digital IDE activation and package contract', () => {
    test('writes info, warning, and error messages without filtering', () => {
        const lines: string[] = [];
        const channel = {
            name: 'test-output',
            append: (value: string) => lines.push(value),
            appendLine: (value: string) => lines.push(value),
            replace: () => undefined,
            clear: () => lines.splice(0),
            show: () => undefined,
            hide: () => undefined,
            dispose: () => undefined,
        } as vscode.OutputChannel;
        const output = new Output(channel);

        output.report('extension started', { level: ReportType.Info });
        output.report('timing constraint missing', { level: ReportType.Warn });
        output.report('request failed', { level: ReportType.Error });

        assert.strictEqual(lines.length, 3);
        assert.match(lines[0], /^\[Info - \d{2}:\d{2}:\d{2}\] extension started$/);
        assert.match(lines[1], /^\[Warn - \d{2}:\d{2}:\d{2}\] timing constraint missing$/);
        assert.match(lines[2], /^\[Error - \d{2}:\d{2}:\d{2}\] request failed$/);
    });

    test('publishes static tool trees while backend initialization is pending', async function () {
        if (process.env.DIGITAL_TEST_COLD_TREE !== '1') {
            this.skip();
        }
        const extension = vscode.extensions.getExtension<DigitalIdeExtensionApi>(
            'sterben.fpga-support',
        );
        assert.ok(extension, 'extension package is unavailable');
        assert.ok(
            extension.isActive,
            'static TreeView providers must be active before the activity bar is clicked',
        );

        const rendererPort = process.env.DIGITAL_TEST_RENDERER_DEBUG_PORT;
        assert.ok(rendererPort, 'renderer debugging port is unavailable');
        const { default: puppeteer } = await import('puppeteer-core');
        const browser = await puppeteer.connect({
            browserURL: `http://127.0.0.1:${rendererPort}`,
        });
        try {
            const pages = await browser.pages();
            const page = pages.find(candidate => candidate.url().includes('workbench'));
            assert.ok(page, `VS Code workbench page is unavailable: ${pages.map(item => item.url())}`);
            const clickActivityBar = async (): Promise<void> => {
                const activityItem = await page.waitForFunction(() => {
                    const items = Array.from(document.querySelectorAll<HTMLElement>('.activitybar *'));
                    return items.find(item => {
                        const label = item.innerText || item.getAttribute('aria-label') || '';
                        return label.toLocaleLowerCase().includes('digital');
                    }) ?? null;
                }, { timeout: 5_000 });
                const element = activityItem.asElement();
                assert.ok(element, 'Digital IDE activity bar item is unavailable');
                const box = await element.boundingBox();
                assert.ok(box, 'Digital IDE activity bar item has no layout box');
                await page.mouse.click(box.x + box.width / 2, box.y + box.height / 2);
            };
            const clickPaneAndWait = async (
                tree: 'hardware' | 'software',
                title: string,
                expected: string[],
            ): Promise<{ clickWallTime: number; domWallTime: number; elapsed: number }> => {
                const headerHandle = await page.waitForFunction((viewTitle: string) => {
                    const normalizedTitle = viewTitle.toLocaleLowerCase();
                    return Array.from(document.querySelectorAll<HTMLElement>('.pane-header'))
                        .find(candidate => candidate.innerText.toLocaleLowerCase()
                            .includes(normalizedTitle)) ?? null;
                }, { timeout: 5_000 }, title);
                const header = headerHandle.asElement();
                assert.ok(header, `${title} pane header is unavailable`);
                const initiallyExpanded = await header.evaluate(element => {
                    const headerElement = element as HTMLElement;
                    return headerElement.getAttribute('aria-expanded') === 'true'
                        || headerElement.parentElement?.classList.contains('expanded') === true;
                });
                assert.strictEqual(
                    initiallyExpanded,
                    false,
                    `${title} must start collapsed for the cold mouse expansion regression`,
                );
                await page.evaluate((viewTitle: string, labels: string[], treeName: string) => {
                    const normalizedTitle = viewTitle.toLocaleLowerCase();
                    const headerElement = Array.from(
                        document.querySelectorAll<HTMLElement>('.pane-header'),
                    ).find(candidate => candidate.innerText.toLocaleLowerCase()
                        .includes(normalizedTitle));
                    const pane = headerElement?.parentElement;
                    if (!headerElement || !pane) {
                        throw new Error(`Missing pane for ${viewTitle}`);
                    }
                    const timing = {
                        tree: treeName,
                        clickWallTime: 0,
                        domWallTime: 0,
                    };
                    (window as unknown as Record<string, unknown>).__digitalIdeTreeTiming = timing;
                    headerElement.addEventListener('pointerdown', () => {
                        timing.clickWallTime = Date.now();
                    }, { once: true });
                    const updateDomTime = () => {
                        const expanded = headerElement.getAttribute('aria-expanded') === 'true'
                            || pane.classList.contains('expanded');
                        const renderedLabels = Array.from(
                            pane.querySelectorAll<HTMLElement>('.monaco-list-row'),
                        ).map(element => element.innerText.trim());
                        if (expanded && timing.clickWallTime > 0
                            && labels.every(label => renderedLabels.includes(label))) {
                            timing.domWallTime = Date.now();
                            observer.disconnect();
                        }
                    };
                    const observer = new MutationObserver(updateDomTime);
                    observer.observe(pane, { childList: true, subtree: true });
                    updateDomTime();
                }, title, expected, tree);
                const box = await header.boundingBox();
                assert.ok(box, `${title} pane header has no layout box`);
                await page.mouse.click(box.x + 12, box.y + box.height / 2);
                try {
                    await page.waitForFunction(
                        (viewTitle: string, expectedLabels: string[]) => {
                            const normalizedTitle = viewTitle.toLocaleLowerCase();
                            const headers = Array.from(
                                document.querySelectorAll<HTMLElement>('.pane-header'),
                            );
                            const header = headers.find(candidate =>
                                candidate.innerText.toLocaleLowerCase().includes(normalizedTitle));
                            const pane = header?.parentElement;
                            if (!pane) {
                                return false;
                            }
                            const labels = Array.from(
                                pane.querySelectorAll<HTMLElement>('.monaco-list-row'),
                            ).map(element => element.innerText.trim());
                            return expectedLabels.every(label => labels.includes(label));
                        },
                        { timeout: 5_000 },
                        title,
                        expected,
                    );
                } catch (error) {
                    const state = await header.evaluate(element => ({
                        ariaExpanded: (element as HTMLElement).getAttribute('aria-expanded'),
                        paneClass: (element as HTMLElement).parentElement?.className,
                        paneText: (element as HTMLElement).parentElement?.innerText,
                    }));
                    console.log(`${title} failed state=${JSON.stringify(state)} `
                        + `trace=${JSON.stringify(extension.exports.project.staticTreeTrace())}`);
                    throw error;
                }
                const timing = await page.evaluate(() => Reflect.get(
                    window,
                    '__digitalIdeTreeTiming',
                ) as { clickWallTime: number; domWallTime: number });
                assert.ok(timing.clickWallTime > 0, `${title} did not receive a pointer event`);
                assert.ok(timing.domWallTime >= timing.clickWallTime, `${title} DOM timing is invalid`);
                return {
                    ...timing,
                    elapsed: timing.domWallTime - timing.clickWallTime,
                };
            };
            const collapsePane = async (title: string): Promise<void> => {
                const headerHandle = await page.waitForFunction((viewTitle: string) => {
                    const normalizedTitle = viewTitle.toLocaleLowerCase();
                    return Array.from(document.querySelectorAll<HTMLElement>('.pane-header'))
                        .find(candidate => candidate.innerText.toLocaleLowerCase()
                            .includes(normalizedTitle)) ?? null;
                }, { timeout: 5_000 }, title);
                const header = headerHandle.asElement();
                assert.ok(header, `${title} pane header is unavailable`);
                const box = await header.boundingBox();
                assert.ok(box, `${title} pane header has no layout box`);
                await page.mouse.click(box.x + 12, box.y + box.height / 2);
                await page.waitForFunction((viewTitle: string) => {
                    const normalizedTitle = viewTitle.toLocaleLowerCase();
                    const headerElement = Array.from(
                        document.querySelectorAll<HTMLElement>('.pane-header'),
                    ).find(candidate => candidate.innerText.toLocaleLowerCase()
                        .includes(normalizedTitle));
                    return headerElement?.getAttribute('aria-expanded') === 'false'
                        || headerElement?.parentElement?.classList.contains('expanded') === false;
                }, { timeout: 5_000 }, title);
            };
            await clickActivityBar();
            const hardwareTiming = await clickPaneAndWait(
                'hardware',
                'HARD Options',
                ['Launch', 'Simulate', 'Refresh', 'Build'],
            );
            await collapsePane('HARD Options');
            const softwareTiming = await clickPaneAndWait(
                'software',
                'SOFT Options',
                ['Launch', 'Build', 'Download'],
            );
            const activation = await extension.activate();
            const trace = activation.project.staticTreeTrace();
            console.log(
                `cold physical expansion HARD=${hardwareTiming.elapsed}ms `
                + `SOFT=${softwareTiming.elapsed}ms trace=${JSON.stringify(trace)}`,
            );
            assert.ok(extension.isActive, 'mouse expansion did not activate the extension');
            assert.deepStrictEqual(
                activation.project.hardwareRoots().map(node => node.label),
                ['Launch', 'Simulate', 'Refresh', 'Build', 'Program', 'GUI', 'Exit'],
            );
            assert.deepStrictEqual(
                activation.project.softwareRoots().map(node => node.label),
                ['Launch', 'Build', 'Download'],
            );
            assert.ok(hardwareTiming.elapsed < 500,
                `first HARD mouse expansion took ${hardwareTiming.elapsed}ms`);
            assert.ok(softwareTiming.elapsed < 500,
                `first SOFT mouse expansion took ${softwareTiming.elapsed}ms`);

            const backendState = await Promise.race([
                activation.ready.then(() => 'ready', () => 'failed'),
                new Promise<'pending'>(resolve => setTimeout(() => resolve('pending'), 250)),
            ]);
            assert.strictEqual(
                backendState,
                'pending',
                'static trees were published only after backend initialization settled',
            );
        } finally {
            await browser.disconnect();
        }
    });

    test('activates the real extension and starts Digital Server', async () => {
        const api = await activateExtension();
        assert.ok(fs.existsSync(api.serverPath), `missing server executable: ${api.serverPath}`);
        assert.strictEqual(api.client.initializeResult?.serverInfo?.name, 'Digital-IDE Backend Server');
        assert.strictEqual(api.client.initializeResult?.serverInfo?.version, '0.5.0');

        const processState = await api.client.sendRequest<{ add: number; cur: number }>(
            'process/request',
        );
        assert.strictEqual(typeof processState.add, 'number');
        assert.strictEqual(typeof processState.cur, 'number');

        const hdlParameters = await api.client.sendRequest<unknown[]>('hdlparams/request');
        assert.ok(Array.isArray(hdlParameters));
        assert.ok(hdlParameters.length >= 8, `expected indexed HDL files, got ${hdlParameters.length}`);
    });

    test('uses exactly three purpose-specific output channels', async () => {
        const api = await activateExtension();
        assert.deepStrictEqual(
            outputChannels.map(channel => channel.name),
            ['Digital-IDE', 'Digital-IDE Hardware', 'Digital-IDE Waveform'],
        );
        assert.strictEqual(mainOutputChannel.name, 'Digital-IDE');
        assert.strictEqual(hardwareOutputChannel.name, 'Digital-IDE Hardware');
        assert.strictEqual(waveOutputChannel.name, 'Digital-IDE Waveform');
        assert.strictEqual(serverOutputChannel.name, 'Digital-IDE');
        assert.strictEqual(api.client.outputChannel, serverOutputChannel);
        assert.strictEqual(MainOutput.name, 'Digital-IDE');
        assert.strictEqual(MainOutput, LinterOutput);
        assert.strictEqual(MainOutput, YosysOutput);
        assert.notStrictEqual(MainOutput, HardwareOutput);
        assert.strictEqual(HardwareOutput.name, 'Digital-IDE Hardware');
        assert.strictEqual(HardwareOutput, HardwareErrorOutput);
        assert.strictEqual(HardwareOutput, DebuggerOutput);
        assert.notStrictEqual(MainOutput, WaveOutput);
        assert.notStrictEqual(HardwareOutput, WaveOutput);
        assert.strictEqual(WaveOutput.name, 'Digital-IDE Waveform');
        assert.strictEqual(WaveOutput, WaveViewOutput);

        assert.strictEqual(classifyLogLevel('INFO initialized'), ReportType.Info);
        assert.strictEqual(classifyLogLevel('WARNING timing constraint missing'), ReportType.Warn);
        assert.strictEqual(classifyLogLevel('ERROR request failed'), ReportType.Error);
        assert.strictEqual(classifyLogLevel('plain tool output'), ReportType.Info);
    });

    test('passes complete startup settings as initialization options', async () => {
        const api = await activateExtension();
        assert.strictEqual(api.initializationOptions.toolChain, 'xilinx');
        assert.strictEqual(api.initializationOptions.version, '0.5.0');
        assert.strictEqual(api.initializationOptions['digital-ide.standard.systemverilog'], '2023');
        assert.strictEqual(
            api.initializationOptions[
                'digital-ide.function.lsp.systemverilog.expandIncludes'
            ],
            true,
        );
        assert.strictEqual(api.initializationOptions['digital-ide.standard.vhdl'], '2008');
        assert.strictEqual(api.initializationOptions['digital-ide.function.lsp.linter.mode'], 'full');
        assert.strictEqual(
            api.initializationOptions['digital-ide.function.lsp.linter.linter-level'],
            'warning',
        );
        assert.strictEqual(
            api.initializationOptions[
                'digital-ide.function.lsp.semantic.tokens.port.clk.rst.enable'
            ],
            true,
        );
        assert.strictEqual(
            api.initializationOptions[
                'digital-ide.function.lsp.semantic.tokens.port.input.output.enable'
            ],
            true,
        );
        assert.strictEqual(
            api.initializationOptions[
                'digital-ide.function.lsp.inlayHints.port.connection.enable'
            ],
            true,
        );
        assert.strictEqual(
            api.initializationOptions[
                'digital-ide.function.lsp.inlayHints.parameter.assignment.enable'
            ],
            true,
        );
        assert.strictEqual(
            api.initializationOptions['digital-ide.lib.vhdl.path'],
            process.env.DIGITAL_SERVER_VHDL_LIBRARY_PATH,
        );
        assert.strictEqual(
            api.initializationOptions['digital-ide.prj.efinix.package.path'],
            vscode.workspace.getConfiguration('digital-ide').get<string>(
                'prj.efinix.package.path',
                '',
            ),
        );
        const legacyEfinityPackageKey = [
            'digital-ide',
            'efinity',
            'package',
            'path',
        ].join('.');
        assert.strictEqual(legacyEfinityPackageKey in api.initializationOptions, false);
        assert.strictEqual(
            api.initializationOptions['digital-ide.efinity.install.path'],
            vscode.workspace.getConfiguration('digital-ide').get<string>(
                'efinity.install.path',
                '',
            ),
        );
    });

    test('advertises every implemented provider and no unsupported provider', async () => {
        const capabilities = (await activateExtension()).client.initializeResult?.capabilities;
        assert.ok(capabilities);
        assert.ok(capabilities.completionProvider);
        assert.deepStrictEqual(capabilities.completionProvider.triggerCharacters, ['.', '$', '`', '"', '/']);
        assert.strictEqual(capabilities.completionProvider.resolveProvider, false);
        assert.deepStrictEqual(capabilities.textDocumentSync, {
            openClose: true,
            change: 2,
            save: {},
        });
        assert.strictEqual(capabilities.definitionProvider, true);
        assert.strictEqual(capabilities.documentHighlightProvider, true);
        assert.strictEqual(capabilities.documentSymbolProvider, true);
        assert.strictEqual(capabilities.hoverProvider, true);
        assert.strictEqual(capabilities.documentFormattingProvider, true);
        assert.strictEqual(capabilities.documentRangeFormattingProvider, false);
        assert.ok(capabilities.codeLensProvider);
        assert.ok(capabilities.inlayHintProvider);
        assert.strictEqual(capabilities.callHierarchyProvider, true);
        assert.strictEqual(capabilities.workspace?.workspaceFolders?.supported, true);

        assert.strictEqual(capabilities.referencesProvider, true);
        assert.deepStrictEqual(capabilities.renameProvider, { prepareProvider: true });
        assert.strictEqual(capabilities.codeActionProvider, undefined);
        assert.strictEqual(capabilities.selectionRangeProvider, undefined);
        assert.ok(capabilities.semanticTokensProvider);
        assert.deepStrictEqual(capabilities.semanticTokensProvider.full, { delta: true });
        assert.strictEqual(capabilities.semanticTokensProvider.range, true);
        assert.deepStrictEqual(
            capabilities.semanticTokensProvider.legend.tokenTypes.slice(-6),
            ['port_clock', 'port_reset', 'port_generic', 'instance', 'type_alias', 'generic'],
        );
        assert.deepStrictEqual(
            capabilities.semanticTokensProvider.legend.tokenModifiers.slice(-4),
            ['read', 'write', 'ref', 'definition'],
        );
        assert.strictEqual(capabilities.workspaceSymbolProvider, true);
        assert.strictEqual(capabilities.typeDefinitionProvider, true);
    });

    test('contributes the complete HDL language, grammar, and configuration surface', async () => {
        const extension = vscode.extensions.getExtension('sterben.fpga-support');
        assert.ok(extension);
        const packageJson = extension.packageJSON as {
            activationEvents: string[];
            contributes: {
                configuration: { properties: Record<string, unknown> };
                configurationDefaults: Record<string, unknown>;
                grammars: Array<{ language: string; path: string }>;
                languages: Array<{ id: string; configuration?: string }>;
            };
        };
        assert.ok(packageJson.activationEvents.includes('workspaceContains:.vscode/property.json'));
        assert.ok(packageJson.activationEvents.includes('onStartupFinished'));
        assert.ok(packageJson.activationEvents.includes('*'));

        const languageIds = new Set(packageJson.contributes.languages.map(language => language.id));
        for (const id of ['systemverilog', 'verilog', 'vhdl', 'tcl', 'ys']) {
            assert.ok(languageIds.has(id), `missing language contribution ${id}`);
        }

        for (const language of ['verilog', 'systemverilog']) {
            const languageDefaults = packageJson.contributes.configurationDefaults[
                `[${language}]`
            ] as { 'editor.quickSuggestions'?: Record<string, string> } | undefined;
            assert.deepStrictEqual(
                languageDefaults?.['editor.quickSuggestions'],
                { other: 'on', comments: 'off', strings: 'off' },
                `${language} must automatically request identifier completions`,
            );
        }

        const semanticColors = packageJson.contributes.configurationDefaults[
            'editor.semanticTokenColorCustomizations'
        ] as { enabled?: boolean; rules?: Record<string, unknown> } | undefined;
        assert.strictEqual(semanticColors?.enabled, true);
        for (const selector of [
            '*.read:verilog',
            '*.write:verilog',
            '*.read:systemverilog',
            '*.write:systemverilog',
        ]) {
            assert.ok(semanticColors?.rules?.[selector], `missing semantic color ${selector}`);
        }

        const settings = packageJson.contributes.configuration.properties;
        for (const key of [
            'digital-ide.standard.systemverilog',
            'digital-ide.function.lsp.systemverilog.expandIncludes',
            'digital-ide.standard.vhdl',
            'digital-ide.function.lsp.linter.mode',
            'digital-ide.function.lsp.linter.linter-level',
            'digital-ide.function.lsp.formatter.vlog.default.style',
            'digital-ide.function.lsp.formatter.vhdl.default.indentation',
            'digital-ide.function.lsp.semantic.tokens.port.clk.rst.enable',
            'digital-ide.function.lsp.semantic.tokens.port.input.output.enable',
            'digital-ide.function.lsp.inlayHints.port.connection.enable',
            'digital-ide.function.lsp.inlayHints.parameter.assignment.enable',
            'digital-ide.prj.efinix.package.path',
            'digital-ide.efinity.install.path',
        ]) {
            assert.ok(key in settings, `missing configuration setting ${key}`);
        }
        assert.deepStrictEqual(
            (settings['digital-ide.standard.systemverilog'] as { enum?: string[] }).enum,
            ['2017', '2023'],
        );
        assert.strictEqual(
            (settings['digital-ide.function.lsp.systemverilog.expandIncludes'] as {
                default?: boolean;
            }).default,
            true,
        );

        for (const grammar of packageJson.contributes.grammars) {
            const grammarPath = path.join(extension.extensionPath, grammar.path);
            assert.ok(fs.existsSync(grammarPath), `missing grammar ${grammarPath}`);
            assert.doesNotThrow(() => JSON.parse(fs.readFileSync(grammarPath, 'utf8')));
        }
        for (const language of packageJson.contributes.languages) {
            if (!language.configuration) {
                continue;
            }
            const configurationPath = path.join(extension.extensionPath, language.configuration);
            assert.ok(fs.existsSync(configurationPath), `missing language config ${configurationPath}`);
            assert.doesNotThrow(() => JSON.parse(fs.readFileSync(configurationPath, 'utf8')));
        }
        for (const catalog of ['primitive.bin', 'primitive.json']) {
            const catalogPath = path.join(
                extension.extensionPath,
                'resources',
                'primitive',
                'xilinx',
                catalog,
            );
            assert.ok(fs.existsSync(catalogPath), `missing Xilinx primitive catalog ${catalogPath}`);
            assert.ok(fs.statSync(catalogPath).size > 0, `empty Xilinx primitive catalog ${catalogPath}`);
            if (catalog === 'primitive.json') {
                const parsed = JSON.parse(fs.readFileSync(catalogPath, 'utf8')) as {
                    modules?: Record<string, unknown>;
                };
                assert.ok(parsed.modules?.IBUF);
                assert.ok(parsed.modules?.xpm_fifo_sync);
            }
        }

        const keywordPairs: Record<string, Array<[string, string]>> = {
            verilog: [
                ['begin', 'end'],
                ['case', 'endcase'],
                ['casex', 'endcase'],
                ['casez', 'endcase'],
                ['config', 'endconfig'],
                ['fork', 'join'],
                ['function', 'endfunction'],
                ['generate', 'endgenerate'],
                ['macromodule', 'endmodule'],
                ['module', 'endmodule'],
                ['primitive', 'endprimitive'],
                ['specify', 'endspecify'],
                ['table', 'endtable'],
                ['task', 'endtask'],
            ],
            systemverilog: [
                ['begin', 'end'],
                ['case', 'endcase'],
                ['casex', 'endcase'],
                ['casez', 'endcase'],
                ['checker', 'endchecker'],
                ['class', 'endclass'],
                ['clocking', 'endclocking'],
                ['config', 'endconfig'],
                ['covergroup', 'endgroup'],
                ['fork', 'join'],
                ['fork', 'join_any'],
                ['fork', 'join_none'],
                ['function', 'endfunction'],
                ['generate', 'endgenerate'],
                ['interface', 'endinterface'],
                ['macromodule', 'endmodule'],
                ['module', 'endmodule'],
                ['package', 'endpackage'],
                ['primitive', 'endprimitive'],
                ['program', 'endprogram'],
                ['property', 'endproperty'],
                ['randcase', 'endcase'],
                ['randsequence', 'endsequence'],
                ['sequence', 'endsequence'],
                ['specify', 'endspecify'],
                ['table', 'endtable'],
                ['task', 'endtask'],
            ],
        };
        for (const [language, requiredPairs] of Object.entries(keywordPairs)) {
            const configurationPath = path.join(
                extension.extensionPath,
                'config',
                `${language}.configuration.json`,
            );
            const configuration = JSON.parse(fs.readFileSync(configurationPath, 'utf8')) as {
                brackets?: Array<[string, string]>;
            };
            const configuredPairs = new Set(
                (configuration.brackets ?? []).map(pair => JSON.stringify(pair)),
            );
            for (const pair of requiredPairs) {
                assert.ok(
                    configuredPairs.has(JSON.stringify(pair)),
                    `${language} is missing keyword pair ${pair[0]}/${pair[1]}`,
                );
            }
        }

        const verilogGrammar = JSON.stringify(JSON.parse(fs.readFileSync(
            path.join(extension.extensionPath, 'syntaxes', 'verilog.json'),
            'utf8',
        )));
        const systemVerilogGrammar = JSON.stringify(JSON.parse(fs.readFileSync(
            path.join(extension.extensionPath, 'syntaxes', 'systemverilog.json'),
            'utf8',
        )));
        assert.ok(verilogGrammar.includes('module|macromodule'));
        assert.ok(systemVerilogGrammar.includes('module|macromodule'));
        assert.ok(systemVerilogGrammar.includes('checker'));
        assert.ok(systemVerilogGrammar.includes('endchecker'));
    });

    test('keeps localization bundles structurally aligned', () => {
        const extension = vscode.extensions.getExtension('sterben.fpga-support');
        assert.ok(extension);
        const locales = ['en', 'de', 'ja', 'zh-cn', 'zh-tw'];
        const keySets = locales.map(locale => {
            const file = path.join(extension.extensionPath, 'l10n', `bundle.l10n.${locale}.json`);
            assert.ok(fs.existsSync(file), `missing localization bundle ${file}`);
            return Object.keys(JSON.parse(fs.readFileSync(file, 'utf8'))).sort();
        });
        for (const keys of keySets.slice(1)) {
            assert.deepStrictEqual(keys, keySets[0]);
        }
    });
});
