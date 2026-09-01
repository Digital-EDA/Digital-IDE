#!/usr/bin/env node

const { spawn, spawnSync } = require('child_process');
const fs = require('fs');
const net = require('net');
const path = require('path');

const container = process.env.DIDE_VCS_DOCKER_CONTAINER;
if (!container) {
    process.stderr.write('DIDE_VCS_DOCKER_CONTAINER is required\n');
    process.exit(2);
}

function findExecutable(root) {
    for (const entry of fs.readdirSync(root, { withFileTypes: true })) {
        if (!entry.isDirectory()) continue;
        const candidate = path.join(root, entry.name, entry.name);
        try {
            fs.accessSync(candidate, fs.constants.X_OK);
            if (fs.statSync(candidate).isFile()) return candidate;
        } catch {
            // Continue until the VCS build directory is found.
        }
    }
    throw new Error(`VCS executable is unavailable below ${root}`);
}

const inspect = spawnSync(
    'docker',
    [
        'inspect',
        '-f',
        '{{range .NetworkSettings.Networks}}{{.IPAddress}}{{end}}',
        container,
    ],
    { encoding: 'utf8' },
);
if (inspect.status !== 0 || !inspect.stdout.trim()) {
    process.stderr.write(inspect.stderr || 'failed to resolve the VCS container address\n');
    process.exit(1);
}

const containerAddress = inspect.stdout.trim();
let executable;
try {
    executable = findExecutable(process.cwd());
} catch (error) {
    process.stderr.write(`${error instanceof Error ? error.message : String(error)}\n`);
    process.exit(1);
}

const child = spawn(
    'docker',
    [
        'exec',
        '-w', path.dirname(executable),
        container,
        'bash', '-lc', 'exec "$@"',
        'digital-ide-vcs',
        executable,
    ],
    { stdio: ['ignore', 'pipe', 'pipe'] },
);
const sockets = new Set();
let proxy;
let stopping = false;

function repairOwnership() {
    if (!process.getuid || !process.getgid) return;
    spawnSync(
        'docker',
        [
            'exec',
            container,
            'chown', '-R', `${process.getuid()}:${process.getgid()}`, '--', process.cwd(),
        ],
        { stdio: 'inherit' },
    );
}

function startProxy(remotePort) {
    if (proxy) return;
    proxy = net.createServer(local => {
        const remote = net.createConnection({ host: containerAddress, port: remotePort });
        sockets.add(local);
        sockets.add(remote);
        local.on('close', () => sockets.delete(local));
        remote.on('close', () => sockets.delete(remote));
        local.on('error', () => remote.destroy());
        remote.on('error', () => local.destroy());
        local.pipe(remote);
        remote.pipe(local);
    });
    proxy.on('error', error => {
        process.stderr.write(`VCS proxy failed: ${error.message}\n`);
        stop('SIGTERM');
    });
    proxy.listen(0, '127.0.0.1', () => {
        const address = proxy.address();
        if (!address || typeof address === 'string') {
            process.stderr.write('VCS proxy did not allocate a TCP port\n');
            stop('SIGTERM');
            return;
        }
        process.stderr.write(`PORT:${address.port}\n`);
    });
}

function forwardLines(stream, destination) {
    let pending = '';
    stream.setEncoding('utf8');
    stream.on('data', chunk => {
        pending += chunk;
        for (;;) {
            const newline = pending.indexOf('\n');
            if (newline < 0) break;
            const line = pending.slice(0, newline + 1);
            pending = pending.slice(newline + 1);
            const match = line.match(/(?:^|\s)PORT:(\d+)/);
            if (match) {
                startProxy(Number(match[1]));
            } else {
                destination.write(line);
            }
        }
    });
    stream.on('end', () => {
        if (pending) destination.write(pending);
    });
}

function stop(signal) {
    if (stopping) return;
    stopping = true;
    for (const socket of sockets) socket.destroy();
    if (proxy) proxy.close();
    child.kill(signal);
    setTimeout(() => process.exit(0), 2000).unref();
}

forwardLines(child.stdout, process.stdout);
forwardLines(child.stderr, process.stderr);
child.on('error', error => {
    process.stderr.write(`${error.message}\n`);
    process.exit(1);
});
child.on('exit', (code, signal) => {
    for (const socket of sockets) socket.destroy();
    if (proxy) proxy.close();
    repairOwnership();
    process.exitCode = signal ? 1 : (code ?? 1);
});
process.on('SIGINT', () => stop('SIGINT'));
process.on('SIGTERM', () => stop('SIGTERM'));
