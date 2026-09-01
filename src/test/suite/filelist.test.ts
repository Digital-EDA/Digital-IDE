import * as assert from 'assert';
import * as fs from 'fs';
import * as path from 'path';
import * as vscode from 'vscode';
import { FilelistResponse } from '../../filelist/commands';
import { SimulationResponse } from '../../simulation/commands';
import {
    activateExtension,
    waitFor,
    workspacePath,
    workspaceUri,
    writeFixture,
} from './helpers';

interface HdlParamElement {
    path: string;
    context: { modules: Record<string, unknown> };
}

interface VendorSimulationReport {
    cacheKey: {
        vendor: string;
        toolVersion: string;
        simulator: string;
        deviceFamily: string;
    };
    cacheHit: boolean;
    exportCacheHit: boolean;
    cacheDir: string;
    modelsimIni: string;
    script: string;
}

function shellQuote(value: string): string {
    return `'${value.replace(/'/g, `'\\''`)}'`;
}

suite('Backend filelist and unified simulation entry', () => {
    test('exports the indexed workspace through the backend', async () => {
        await activateExtension();
        const output = path.join(workspacePath(), 'project', 'simulation', 'filelist', 'export.f');
        const response = await vscode.commands.executeCommand<FilelistResponse>(
            'digital-ide.tool.export-filelist',
            { path: output, scope: 'all', relativePaths: true, silent: true },
        );
        assert.strictEqual(response.success, true);
        assert.strictEqual(response.applied, true);
        assert.ok(response.files.some(file => file.endsWith('src/sv/top.sv')));
        const contents = fs.readFileSync(output, 'utf8');
        const workspaceEpoch = contents.match(/workspaceEpoch=(\d+)/);
        const configGeneration = contents.match(/configGeneration=(\d+)/);
        assert.ok(workspaceEpoch);
        assert.ok(configGeneration);
        assert.strictEqual(Number(workspaceEpoch[1]), response.workspaceEpoch);
        assert.strictEqual(Number(configGeneration[1]), response.configGeneration);
        assert.ok(contents.includes('src/sv/top.sv'));
        assert.ok(contents.indexOf('src/sv/leaf.sv') < contents.indexOf('src/sv/child.sv'));
        assert.ok(contents.indexOf('src/sv/child.sv') < contents.indexOf('src/sv/top.sv'));
    });

    test('previews then atomically applies a nested filelist import', async () => {
        const api = await activateExtension();
        await writeFixture(
            'filelist-import/rtl/imported.sv',
            '`ifdef FILELIST_FLAG\nmodule imported_filelist; endmodule\n`endif\n',
        );
        await writeFixture('filelist-import/include/defs.svh', '`define IMPORTED_WIDTH 8\n');
        await writeFixture(
            'filelist-import/lists/nested/child.f',
            '../../rtl/imported.sv\n../../include/defs.svh\n'
                + '+incdir+../../include\n+define+FILELIST_FLAG+WIDTH=8\n',
        );
        const root = await writeFixture(
            'filelist-import/lists/root.f',
            '-f nested/child.f\n',
        );
        const propertyPath = path.join(workspacePath(), '.vscode', 'property.json');
        const before = fs.readFileSync(propertyPath, 'utf8');

        const preview = await vscode.commands.executeCommand<FilelistResponse>(
            'digital-ide.tool.import-filelist',
            { path: root, kind: 'src', apply: false, silent: true },
        );
        assert.strictEqual(preview.success, true);
        assert.strictEqual(preview.applied, false);
        assert.ok(preview.files.some(file => file.endsWith('imported.sv')));
        assert.strictEqual(preview.defines.FILELIST_FLAG, null);
        assert.strictEqual(fs.readFileSync(propertyPath, 'utf8'), before);

        const applied = await vscode.commands.executeCommand<FilelistResponse>(
            'digital-ide.tool.import-filelist',
            { path: root.fsPath, kind: 'src', apply: true, silent: true },
        );
        assert.strictEqual(applied.success, true);
        assert.strictEqual(applied.applied, true);
        assert.ok(applied.configGeneration >= preview.configGeneration);
        const property = JSON.parse(fs.readFileSync(propertyPath, 'utf8'));
        assert.ok(property.files.src.includes('filelist-import/rtl/imported.sv'));
        assert.deepStrictEqual(property.filelist.defines, {
            ['FILELIST_FLAG']: null,
            ['WIDTH']: '8',
        });
        assert.ok(property.filelist.includeDirs.includes('filelist-import/include'));

        const parameters = await waitFor(
            'filelist-imported module to enter the server index',
            () => api.client.sendRequest<HdlParamElement[]>('hdlparams/request'),
            values => values.some(value => 'imported_filelist' in value.context.modules),
        );
        assert.ok(parameters.some(value => value.path.endsWith('imported.sv')));
    });

    test('keeps the old command id as a real Verilator alias', async function () {
        this.timeout(60_000);
        const api = await activateExtension();
        const source = await writeFixture(
            'src/sv/compat_sim.sv',
            'module compat_sim; initial begin #1 $finish; end endmodule\n',
        );
        await waitFor(
            'compatibility simulation source to enter the server index',
            () => api.client.sendRequest<HdlParamElement[]>('hdlparams/request'),
            values => values.some(value => 'compat_sim' in value.context.modules),
        );

        const response = await vscode.commands.executeCommand<SimulationResponse>(
            'digital-ide.tool.icarus.simulateFile',
            {
                fileUri: source,
                moduleName: 'compat_sim',
                backend: 'verilator',
                silent: true,
            },
        );
        assert.strictEqual(response.success, true);
        assert.strictEqual(response.backend, 'verilator');
        assert.strictEqual(
            response.simulationHome,
            path.join(workspacePath(), 'prj', 'simulation', 'verilator', 'compat_sim'),
        );
        assert.ok(!fs.existsSync(path.join(
            workspacePath(), 'project', 'simulation', 'verilator', 'compat_sim',
        )));
        assert.ok(response.artifacts.some(artifact => artifact.kind === 'executable'));
        const serialized = JSON.stringify(response).toLowerCase();
        assert.ok(!serialized.includes('iverilog'));
        assert.ok(!serialized.includes('vvp'));
        assert.ok(!fs.existsSync(path.join(workspacePath(), 'verilator')));
        assert.ok(!fs.existsSync(path.join(workspacePath(), 'modelsim')));
        const waveform = api.waveform;
        assert.ok(waveform, 'waveform extension API is unavailable');
        assert.strictEqual(waveform.activePanelCount, 1);
        assert.strictEqual(
            vscode.window.tabGroups.activeTabGroup.activeTab?.label,
            'compat_sim (VERILATOR)',
        );
        await vscode.commands.executeCommand('workbench.action.closeActiveEditor');
        await waitFor(
            'Verilator waveform Webview disposal',
            () => waveform.activePanelCount,
            count => count === 0,
        );
    });

    test('builds CXXRTL and connects its executable to the waveform Webview', async function () {
        this.timeout(120_000);
        const api = await activateExtension();
        const waveform = api.waveform;
        assert.ok(waveform, 'waveform extension API is unavailable');
        const source = await writeFixture(
            'src/verilog/cxxrtl_live.v',
            'module cxxrtl_live(input wire clk, input wire d, output reg q);\n'
                + 'always @(posedge clk) q <= d;\n'
                + 'endmodule\n',
        );
        await waitFor(
            'CXXRTL simulation source to enter the server index',
            () => api.client.sendRequest<HdlParamElement[]>('hdlparams/request'),
            values => values.some(value => 'cxxrtl_live' in value.context.modules),
        );

        const response = await vscode.commands.executeCommand<SimulationResponse>(
            'digital-ide.tool.simulateFile',
            {
                fileUri: source,
                moduleName: 'cxxrtl_live',
                backend: 'cxxrtl',
                silent: true,
            },
        );
        assert.strictEqual(response.success, true);
        assert.strictEqual(response.backend, 'cxxrtl');
        assert.strictEqual(
            response.simulationHome,
            path.join(workspacePath(), 'prj', 'simulation', 'cxxrtl', 'cxxrtl_live'),
        );
        const executable = response.artifacts.find(artifact => artifact.kind === 'executable');
        assert.ok(executable && fs.existsSync(executable.path));
        assert.strictEqual(waveform.activePanelCount, 1);
        assert.strictEqual(
            vscode.window.tabGroups.activeTabGroup.activeTab?.label,
            'cxxrtl_live (CXXRTL)',
        );
        await vscode.commands.executeCommand('workbench.action.closeActiveEditor');
        await waitFor(
            'CXXRTL waveform Webview disposal',
            () => waveform.activePanelCount,
            count => count === 0,
        );
    });

    test('builds ModelSim and Questa VPI sessions and connects them to the waveform Webview', async function () {
        if (!process.env.DIDE_MODELSIM_BIN) {
            this.skip();
            return;
        }
        this.timeout(240_000);
        const api = await activateExtension();
        const waveform = api.waveform;
        assert.ok(waveform, 'waveform extension API is unavailable');
        const source = await writeFixture(
            'src/verilog/modelsim_live.v',
            'module modelsim_live(input wire clk, input wire d, output reg q);\n'
                + 'always @(posedge clk) q <= d;\n'
                + 'endmodule\n',
        );
        await waitFor(
            'ModelSim simulation source to enter the server index',
            () => api.client.sendRequest<HdlParamElement[]>('hdlparams/request'),
            values => values.some(value => 'modelsim_live' in value.context.modules),
        );

        for (const backend of ['modelsim', 'questa'] as const) {
            const response = await vscode.commands.executeCommand<SimulationResponse>(
                'digital-ide.tool.simulateFile',
                {
                    fileUri: source,
                    moduleName: 'modelsim_live',
                    backend,
                    silent: true,
                    options: { vendorPrepare: false },
                },
            );
            assert.strictEqual(response.success, true);
            assert.strictEqual(
                response.simulationHome,
                path.join(workspacePath(), 'prj', 'simulation', backend, 'modelsim_live'),
            );
            const executable = response.artifacts.find(artifact => artifact.kind === 'executable');
            assert.ok(executable && fs.existsSync(executable.path));
            assert.ok(executable.args?.includes('-pli'));
            assert.ok(executable.args?.includes('run -all'));
            assert.ok(executable.cwd && fs.statSync(executable.cwd).isDirectory());
            assert.strictEqual(waveform.activePanelCount, 1);
            assert.strictEqual(
                vscode.window.tabGroups.activeTabGroup.activeTab?.label,
                `modelsim_live (${backend.toUpperCase()})`,
            );
            await vscode.commands.executeCommand('workbench.action.closeActiveEditor');
            await waitFor(
                `${backend} waveform Webview disposal`,
                () => waveform.activePanelCount,
                count => count === 0,
            );
        }
    });

    test('routes VHDL and explicit Questa requests without launching tools in dry-run', async () => {
        await activateExtension();
        const vhdl = workspaceUri('src/vhdl/top.vhd');
        const modelsim = await vscode.commands.executeCommand<SimulationResponse>(
            'digital-ide.tool.simulateFile',
            { fileUri: vhdl, moduleName: 'top_vhdl', dryRun: true, silent: true },
        );
        assert.strictEqual(modelsim.backend, 'modelsim');
        assert.strictEqual(modelsim.dryRun, true);
        assert.strictEqual(
            modelsim.simulationHome,
            path.join(workspacePath(), 'prj', 'simulation', 'modelsim', 'top_vhdl'),
        );
        const modelsimPlan = modelsim.report as {
            designGraphDigest: string;
            sourceFiles: string[];
        };
        assert.ok(modelsimPlan.designGraphDigest.length > 0);
        assert.ok(modelsimPlan.sourceFiles.some(file => file.endsWith('top.vhd')));

        const questa = await vscode.commands.executeCommand<SimulationResponse>(
            'digital-ide.tool.simulateFile',
            {
                fileUri: vhdl,
                moduleName: 'top_vhdl',
                backend: 'questa',
                dryRun: true,
                silent: true,
            },
        );
        assert.strictEqual(questa.backend, 'questa');
        assert.strictEqual(
            (questa.report as { designGraphDigest: string }).designGraphDigest,
            modelsimPlan.designGraphDigest,
        );
        assert.strictEqual(
            questa.simulationHome,
            path.join(workspacePath(), 'prj', 'simulation', 'questa', 'top_vhdl'),
        );
    });

    test('runs interactive vendor library preparation, IP export, mapping, and cache reuse through LSP', async function () {
        if (process.platform === 'win32') {
            this.skip();
        }
        this.timeout(60_000);
        const api = await activateExtension();

        const workspace = workspacePath();
        const moduleName = 'tb_vendor_electron';
        const testbench = await writeFixture(
            `sim/${moduleName}.v`,
            `module ${moduleName}; initial begin #1 $finish; end endmodule\n`,
        );
        await writeFixture('user/ip/electron_vendor/electron_vendor.xci', 'fake xci\n');

        const generated = path.join(workspace, 'prj', 'simulation', 'vendor-electron');
        const tools = path.join(generated, 'tools');
        const cacheRoot = path.join(generated, 'cache');
        const simulationHome = path.join(
            workspace,
            'prj',
            'simulation',
            'modelsim',
            moduleName,
        );
        const vendorHome = path.join(simulationHome, 'vendor', 'xilinx');
        const compileDirectory = path.join(
            vendorHome,
            'export',
            'electron_vendor',
            'modelsim',
        );
        const calls = path.join(generated, 'calls.log');
        fs.mkdirSync(tools, { recursive: true });

        const vivado = path.join(tools, 'vivado');
        fs.writeFileSync(
            vivado,
            `#!/bin/sh
if [ "\${1:-}" = "-version" ]; then
  echo "Vivado v2022.2 (64-bit)"
  exit 0
fi
tcl=""
previous=""
for argument in "$@"; do
  if [ "$previous" = "-source" ]; then tcl="$argument"; fi
  previous="$argument"
done
if grep -q compile_simlib "$tcl"; then
  echo compile >> ${shellQuote(calls)}
  mkdir -p ${shellQuote(path.join(cacheRoot, 'xilinx', '2022.2', 'modelsim', 'artix7'))}
  printf '[Library]\n' > ${shellQuote(path.join(
                cacheRoot,
                'xilinx',
                '2022.2',
                'modelsim',
                'artix7',
                'modelsim.ini',
            ))}
  exit 0
fi
echo export >> ${shellQuote(calls)}
mkdir -p ${shellQuote(compileDirectory)}
printf 'vmap electron_vendor modelsim_lib/msim/electron_vendor\n' > ${shellQuote(path.join(compileDirectory, 'compile.do'))}
printf 'xil_defaultlib\tVerilog\t%s\n' ${shellQuote(testbench.fsPath)} > ${shellQuote(path.join(vendorHome, 'compile-order.tsv'))}
exit 0
`,
        );
        fs.chmodSync(vivado, 0o755);

        const vsim = path.join(tools, 'vsim');
        fs.writeFileSync(vsim, `#!/bin/sh\necho run >> ${shellQuote(calls)}\nexit 0\n`);
        fs.chmodSync(vsim, 0o755);
        const options = {
            vivadoPath: vivado,
            vsimPath: vsim,
            vendorCacheRoot: cacheRoot,
            vendorRuntime: '10ns',
        };

        const request = {
            backend: 'modelsim',
            workspaceUri: vscode.Uri.file(workspace).toString(),
            fileUri: testbench.toString(),
            moduleName,
            interactive: true,
            options,
        };
        const first = await api.client.sendRequest<SimulationResponse>(
            'digital/simulate',
            request,
        );
        assert.strictEqual(first.success, true);
        assert.strictEqual(first.simulationHome, simulationHome);
        assert.ok(!fs.existsSync(path.join(
            workspace, 'project', 'simulation', 'modelsim', moduleName,
        )));
        const firstReport = first.report as unknown as VendorSimulationReport;
        assert.deepStrictEqual(firstReport.cacheKey, {
            vendor: 'xilinx',
            toolVersion: '2022.2',
            simulator: 'modelsim',
            deviceFamily: 'artix7',
        });
        assert.strictEqual(firstReport.cacheHit, false);
        assert.strictEqual(firstReport.exportCacheHit, false);
        assert.ok(first.artifacts.some(artifact => artifact.kind === 'vendorLibraryManifest'));
        assert.ok(first.artifacts.some(artifact => artifact.kind === 'vendorExportManifest'));
        assert.ok(first.artifacts.some(artifact => artifact.kind === 'vendorSimulationScript'));
        for (const artifact of first.artifacts) {
            assert.ok(fs.existsSync(artifact.path), `missing simulation artifact: ${artifact.path}`);
        }

        const cached = await api.client.sendRequest<SimulationResponse>(
            'digital/simulate',
            request,
        );
        const cachedReport = cached.report as unknown as VendorSimulationReport;
        assert.strictEqual(cachedReport.cacheHit, true);
        assert.strictEqual(cachedReport.exportCacheHit, true);
        assert.match(fs.readFileSync(cachedReport.script, 'utf8'), /-L "electron_vendor"/);

        const callLines = fs.readFileSync(calls, 'utf8').trim().split(/\r?\n/);
        assert.strictEqual(callLines.filter(line => line === 'compile').length, 1);
        assert.strictEqual(callLines.filter(line => line === 'export').length, 1);
        assert.strictEqual(callLines.filter(line => line === 'run').length, 2);

        fs.writeFileSync(
            vsim,
            `#!/bin/sh\necho intentional vendor failure >&2\nexit 7\n`,
        );
        await assert.rejects(
            async () => {
                const failed = await api.client.sendRequest<SimulationResponse>(
                    'digital/simulate',
                    {
                        ...request,
                        options: { ...options, vendorRuntime: '20ns' },
                    },
                );
                assert.strictEqual(failed.success, true, failed.message);
            },
            /generated ModelSim\/Questa script failed.*intentional vendor failure/,
        );
        const failedCallLines = fs.readFileSync(calls, 'utf8').trim().split(/\r?\n/);
        assert.strictEqual(failedCallLines.filter(line => line === 'export').length, 1);
    });
});
