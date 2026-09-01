import * as assert from 'assert';
import * as vscode from 'vscode';
import {
    activateExtension,
    closeDocument,
    openFixture,
    positionOf,
} from './helpers';

interface SyncState {
    version?: number;
    textHash?: string;
    textBytes?: number;
}

function percentile(values: number[], ratio: number): number {
    const sorted = [...values].sort((left, right) => left - right);
    return sorted[Math.round((sorted.length - 1) * ratio)];
}

suite('Desktop synchronization performance', () => {
    suiteSetup(async () => {
        await activateExtension();
    });

    test('sustains 200 frontend edits at a 20ms cadence', async () => {
        const api = await activateExtension();
        const document = await openFixture('src/sv/scopes.sv');
        const latencies: number[] = [];
        for (let index = 0; index < 200; index += 1) {
            const tick = performance.now();
            const edit = new vscode.WorkspaceEdit();
            const marker = /SYNC_COUNTER=\d+/.exec(document.getText());
            const replacement = `SYNC_COUNTER=${index}`;
            if (marker) {
                edit.replace(
                    document.uri,
                    new vscode.Range(
                        document.positionAt(marker.index),
                        document.positionAt(marker.index + marker[0].length),
                    ),
                    replacement,
                );
            } else {
                edit.insert(document.uri, new vscode.Position(1, 0), `  localparam ${replacement};\n`);
            }
            assert.ok(await vscode.workspace.applyEdit(edit));
            const state = await api.client.sendRequest<SyncState>('digital/debugState', {
                uri: document.uri.toString(),
            });
            assert.strictEqual(state.version, document.version);
            latencies.push(performance.now() - tick);
            const remaining = 20 - (performance.now() - tick);
            if (remaining > 0) {
                await new Promise(resolve => setTimeout(resolve, remaining));
            }
        }
        const p95 = percentile(latencies, 0.95);
        const p99 = percentile(latencies, 0.99);
        assert.ok(p95 <= 20, `edit sync P95 ${p95.toFixed(2)}ms exceeded 20ms`);
        assert.ok(p99 <= 50, `edit sync P99 ${p99.toFixed(2)}ms exceeded 50ms`);

        const start = performance.now();
        const completion = await vscode.commands.executeCommand<vscode.CompletionList>(
            'vscode.executeCompletionItemProvider',
            document.uri,
            positionOf(document, 'value =', 2),
        );
        const completionLatency = performance.now() - start;
        console.log(
            `desktop synchronization P95=${p95.toFixed(2)}ms P99=${p99.toFixed(2)}ms `
            + `completion=${completionLatency.toFixed(2)}ms`,
        );
        assert.ok(completion.items.some(item => item.label === 'value'));
        assert.ok(completionLatency <= 250, `completion took ${completionLatency.toFixed(2)}ms`);
        await closeDocument(document);
    });
});
