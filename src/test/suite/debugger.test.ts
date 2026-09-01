import * as assert from 'assert';
import * as fs from 'fs';
import * as path from 'path';
import * as vscode from 'vscode';
import { activateExtension, waitFor, workspacePath } from './helpers';

suite('Native debugger desktop chain', () => {
    test('VS Code command loads a hash-verified manifest through LSP', async () => {
        const api = await activateExtension();
        assert.ok(api.debugger, 'debugger extension API is unavailable');
        const output = vscode.Uri.file(path.join(workspacePath(), 'project', 'debugger'));
        const bundle = await vscode.commands.executeCommand<{
            manifest: { top: string; vendor: string; hardware_hash: string };
        }>('digital-ide.debugger.refresh', {
            workspaceUri: vscode.Uri.file(workspacePath()),
            top: 'electron_debug_top',
            vendor: 'efinity',
            artifactUri: output,
        });
        assert.strictEqual(bundle.manifest.top, 'electron_debug_top');
        assert.strictEqual(bundle.manifest.vendor, 'efinity');
        assert.strictEqual(bundle.manifest.hardware_hash, 'electron-debug-hardware');
        assert.strictEqual(api.debugger.manifest()?.manifest.top, 'electron_debug_top');

        const commands = await vscode.commands.getCommands(true);
        for (const command of [
            'digital-ide.debugger.status',
            'digital-ide.debugger.capture',
            'digital-ide.debugger.stop',
            'digital-ide.debugger.vioRead',
            'digital-ide.debugger.vioWrite',
        ]) {
            assert.ok(commands.includes(command), `missing desktop command ${command}`);
        }
    });

    test('LSP refuses an active metadata publication and a modified bitstream', async () => {
        const api = await activateExtension();
        assert.ok(api.debugger);
        const outputPath = path.join(workspacePath(), 'project', 'debugger');
        const options = {
            workspaceUri: vscode.Uri.file(workspacePath()),
            artifactUri: vscode.Uri.file(outputPath),
        };
        const lock = vscode.Uri.file(path.join(outputPath, '.debugpublish.lock'));
        await vscode.workspace.fs.writeFile(lock, Buffer.from('test'));
        await assert.rejects(api.debugger.refresh(options), /publication is incomplete or active/);
        await vscode.workspace.fs.delete(lock);

        const bitstream = vscode.Uri.file(path.join(outputPath, 'top.hex'));
        await vscode.workspace.fs.writeFile(bitstream, Buffer.from('stale'));
        await assert.rejects(api.debugger.refresh(options), /changed after the published Debug Build/);
        await vscode.workspace.fs.writeFile(bitstream, Buffer.from('bitstream'));
        await api.debugger.refresh(options);
    });

    test('VS Code drives Vivado status and capture through LSP into Wave Server', async () => {
        const api = await activateExtension();
        assert.ok(api.debugger);
        const output = vscode.Uri.file(path.join(
            workspacePath(),
            'project',
            'vivado-debugger',
        ));
        const command = process.env.DIGITAL_TEST_VIVADO_DEBUGGER;
        assert.ok(command, 'Vivado debugger fixture is unavailable');
        const build = {
            workspaceUri: vscode.Uri.file(workspacePath()),
            top: 'electron_vivado_top',
            vendor: 'vivado',
            artifactUri: output,
            transport: {
                backend: 'vivado',
                command,
                program: false,
                timeoutMs: 10_000,
            },
        } as const;
        const bundle = await api.debugger.refresh(build);
        assert.strictEqual(bundle.manifest.vendor, 'vivado');
        assert.strictEqual(bundle.manifest.ila.length, 1);

        const status = await vscode.commands.executeCommand<{
            state: string;
            sampleCount: number;
        }>('digital-ide.debugger.status', {
            ...build,
            core: { kind: 'ila', id: 0 },
            silent: true,
        });
        assert.strictEqual(status.state, 'ready');
        assert.strictEqual(status.sampleCount, 17);

        const capture = await vscode.commands.executeCommand<{
            samples: number;
            signals: number;
            timeRange: [number, number];
        }>('digital-ide.debugger.capture', {
            ...build,
            core: { kind: 'ila', id: 0 },
        });
        assert.strictEqual(capture.samples, 2);
        assert.strictEqual(capture.signals, 2);
        assert.deepStrictEqual(capture.timeRange, [0, 1]);
        const active = vscode.window.tabGroups.activeTabGroup.activeTab;
        assert.ok(active, 'debug capture did not open the waveform Webview');
        assert.strictEqual(active.label, 'ILA 0 Capture');
        const launches = process.env.DIGITAL_TEST_VIVADO_DEBUGGER_LAUNCHES;
        const requests = process.env.DIGITAL_TEST_VIVADO_DEBUGGER_REQUESTS;
        assert.ok(launches && requests);
        assert.strictEqual(fs.readFileSync(launches, 'utf8').trim().split(/\r?\n/).length, 1);
        assert.ok(fs.readFileSync(requests, 'utf8').trim().split(/\r?\n/).length >= 3);
        await vscode.commands.executeCommand('workbench.action.closeActiveEditor');
        await waitFor(
            'debug capture waveform Webview disposal',
            () => api.waveform?.activePanelCount ?? 0,
            count => count === 0,
        );
    });

    test('VS Code reads and commits Vivado VIO through the complete LSP chain', async () => {
        const api = await activateExtension();
        assert.ok(api.debugger);
        const output = vscode.Uri.file(path.join(
            workspacePath(),
            'project',
            'vivado-debugger',
        ));
        const command = process.env.DIGITAL_TEST_VIVADO_DEBUGGER;
        assert.ok(command, 'Vivado debugger fixture is unavailable');
        const build = {
            workspaceUri: vscode.Uri.file(workspacePath()),
            top: 'electron_vivado_top',
            vendor: 'vivado',
            artifactUri: output,
            core: { kind: 'vio', id: 0 },
            transport: {
                backend: 'vivado',
                command,
                program: false,
                timeoutMs: 10_000,
            },
            silent: true,
        } as const;
        const bundle = await api.debugger.refresh(build);
        assert.strictEqual(bundle.manifest.vio.length, 1);
        assert.strictEqual(bundle.manifest.vio[0].inputs[0].name, 'status');
        assert.strictEqual(bundle.manifest.vio[0].outputs[0].name, 'control');

        const read = await vscode.commands.executeCommand<{
            values: Record<string, string>;
        }>('digital-ide.debugger.vioRead', build);
        assert.deepStrictEqual(read.values, { status: '0b1010' });

        const write = await vscode.commands.executeCommand<{
            committed: boolean;
            values: Record<string, string>;
        }>('digital-ide.debugger.vioWrite', {
            ...build,
            values: { control: '0b0101' },
        });
        assert.strictEqual(write.committed, true);
        assert.deepStrictEqual(write.values, { status: '0b0101' });
        const launches = process.env.DIGITAL_TEST_VIVADO_DEBUGGER_LAUNCHES;
        assert.ok(launches);
        assert.strictEqual(fs.readFileSync(launches, 'utf8').trim().split(/\r?\n/).length, 1);
    });

    test('VS Code stop cancels an active Vivado Hardware Manager process', async () => {
        const output = vscode.Uri.file(path.join(
            workspacePath(),
            'project',
            'vivado-debugger',
        ));
        const command = process.env.DIGITAL_TEST_VIVADO_DEBUGGER_SLEEP;
        assert.ok(command, 'sleeping Vivado fixture is unavailable');
        const options = {
            workspaceUri: vscode.Uri.file(workspacePath()),
            artifactUri: output,
            core: { kind: 'ila', id: 0 },
            transport: {
                backend: 'vivado',
                command,
                program: false,
                timeoutMs: 10_000,
            },
            waveformUrl: process.env.DIGITAL_TEST_WAVEFORM_URL,
            silent: true,
        };
        const capture = vscode.commands.executeCommand(
            'digital-ide.debugger.capture',
            options,
        );
        const started = process.env.DIGITAL_TEST_VIVADO_DEBUGGER_SLEEP_STARTED;
        assert.ok(started, 'sleeping Vivado start marker is unavailable');
        const deadline = Date.now() + 5_000;
        while (!fs.existsSync(started)) {
            if (Date.now() >= deadline) {
                await capture;
                assert.fail('sleeping Vivado fixture did not start');
            }
            await new Promise(resolve => setTimeout(resolve, 20));
        }
        const stopped = await vscode.commands.executeCommand<{ cancelled: boolean }>(
            'digital-ide.debugger.stop',
            options,
        );
        assert.strictEqual(stopped.cancelled, true);
        await assert.rejects(async () => capture, /cancelled/);
    });
});
