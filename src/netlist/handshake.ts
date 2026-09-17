export interface NetlistLifecycleMessage {
    protocolVersion?: unknown;
    sessionId?: unknown;
    type?: unknown;
    message?: unknown;
}

export function createNetlistHandshake(
    sessionId: string,
    onProgress: (stage: string) => void,
): {
    ready: Promise<void>;
    receive: (message: NetlistLifecycleMessage) => void;
    cancel: (error: Error) => void;
} {
    let settled = false;
    let started = false;
    let lastStage = 'frontend startup';
    let resolveReady: () => void;
    let rejectReady: (error: Error) => void;
    const ready = new Promise<void>((resolve, reject) => {
        resolveReady = resolve;
        rejectReady = reject;
    });
    const finish = (error?: Error): void => {
        if (settled) {
            return;
        }
        settled = true;
        clearTimeout(timer);
        if (error) {
            rejectReady(error);
        } else {
            resolveReady();
        }
    };
    let timer = setTimeout(() => {
        finish(new Error('Netlist Webview frontend did not start within 30s'));
    }, 30_000);
    return {
        ready,
        cancel: finish,
        receive(raw): void {
            if (settled || raw?.protocolVersion !== 2 || raw.sessionId !== sessionId) {
                return;
            }
            if (raw.type === 'netlist.started' && !started) {
                started = true;
                clearTimeout(timer);
                // Rendering is CPU work; it must not share the frontend startup deadline.
                timer = setTimeout(() => {
                    finish(new Error(`Netlist rendering exceeded 180s (last stage: ${lastStage})`));
                }, 180_000);
            } else if (raw.type === 'netlist.progress' && typeof raw.message === 'string') {
                lastStage = raw.message;
                onProgress(lastStage);
            } else if (raw.type === 'netlist.ready') {
                finish();
            } else if (raw.type === 'netlist.error') {
                const detail = typeof raw.message === 'string' ? raw.message : 'unknown error';
                finish(new Error(`Netlist Webview initialization failed: ${detail}`));
            }
        },
    };
}
