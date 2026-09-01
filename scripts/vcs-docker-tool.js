#!/usr/bin/env node

const { spawnSync } = require('child_process');
const path = require('path');

const container = process.env.DIDE_VCS_DOCKER_CONTAINER;
if (!container) {
    process.stderr.write('DIDE_VCS_DOCKER_CONTAINER is required\n');
    process.exit(2);
}

const toolNames = {
    cxx: 'g++',
    vcs: 'vcs',
    vhdlan: 'vhdlan',
    vlogan: 'vlogan',
};
const wrapperName = path.basename(process.argv[1]);
const tool = toolNames[wrapperName];
if (!tool) {
    process.stderr.write(`unsupported VCS Docker tool wrapper: ${wrapperName}\n`);
    process.exit(2);
}

const result = spawnSync(
    'docker',
    [
        'exec',
        '-w', process.cwd(),
        container,
        'bash', '-lc', 'exec "$@"',
        'digital-ide-vcs',
        tool,
        ...process.argv.slice(2),
    ],
    { stdio: 'inherit' },
);
if (process.getuid && process.getgid) {
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
if (result.error) {
    process.stderr.write(`${result.error.message}\n`);
    process.exit(1);
}
process.exit(result.status ?? 1);
