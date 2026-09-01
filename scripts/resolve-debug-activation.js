'use strict';

const fs = require('fs');
const path = require('path');
const createIgnore = require('ignore');

const hdlExtensions = new Set(['.v', '.sv', '.vh', '.svh', '.vhd', '.vhdl']);

function configuredEntries(property) {
    const hardware = property?.arch?.hardware ?? {};
    const files = property?.files ?? {};
    const entries = [hardware.src, hardware.sim];
    for (const name of ['src', 'sim']) {
        if (Array.isArray(files[name])) {
            entries.push(...files[name]);
        }
    }
    return entries.filter(entry => typeof entry === 'string' && entry.length > 0);
}

function resolvePropertyPath(workspace, property, value) {
    const projectNames = property?.prjName ?? {};
    const expanded = value
        .replaceAll('${workspace}', workspace)
        .replaceAll('${plname}', typeof projectNames.PL === 'string' ? projectNames.PL : '')
        .replaceAll('${psname}', typeof projectNames.PS === 'string' ? projectNames.PS : '');
    return path.resolve(workspace, expanded);
}

function collectHdlFiles(candidate, output) {
    let status;
    try {
        status = fs.lstatSync(candidate);
    } catch (error) {
        if (error?.code === 'ENOENT') {
            return;
        }
        throw error;
    }
    if (status.isSymbolicLink()) {
        return;
    }
    if (status.isFile()) {
        if (hdlExtensions.has(path.extname(candidate).toLowerCase())) {
            output.push(fs.realpathSync(candidate));
        }
        return;
    }
    if (!status.isDirectory()) {
        return;
    }
    const entries = fs.readdirSync(candidate, { withFileTypes: true })
        .sort((left, right) => left.name.localeCompare(right.name));
    for (const entry of entries) {
        collectHdlFiles(path.join(candidate, entry.name), output);
    }
}

function workspaceRelativePath(workspace, candidate) {
    const relative = path.relative(workspace, candidate);
    if (relative.length === 0 || relative === '..' || relative.startsWith(`..${path.sep}`)
        || path.isAbsolute(relative)) {
        return undefined;
    }
    return relative.split(path.sep).join('/');
}

function resolveDebugActivation(workspacePath) {
    const workspace = fs.realpathSync(workspacePath);
    const propertyPath = path.join(workspace, '.vscode', 'property.json');
    const property = JSON.parse(fs.readFileSync(propertyPath, 'utf8'));
    const matcher = createIgnore();
    const ignorePath = path.join(workspace, '.dideignore');
    if (fs.existsSync(ignorePath)) {
        matcher.add(fs.readFileSync(ignorePath, 'utf8'));
    }

    const excluded = new Set((property?.files?.exclude ?? [])
        .filter(value => typeof value === 'string' && value.length > 0)
        .map(value => resolvePropertyPath(workspace, property, value)));
    const candidates = [];
    for (const entry of configuredEntries(property)) {
        collectHdlFiles(resolvePropertyPath(workspace, property, entry), candidates);
    }
    const uniqueCandidates = [...new Set(candidates)].sort((left, right) => left.localeCompare(right));
    return uniqueCandidates.find(candidate => {
        if (excluded.has(candidate)) {
            return false;
        }
        const relative = workspaceRelativePath(workspace, candidate);
        return relative === undefined || !matcher.ignores(relative);
    });
}

if (require.main === module) {
    const workspace = process.argv[2];
    if (!workspace) {
        process.stderr.write('Usage: node resolve-debug-activation.js WORKSPACE\n');
        process.exitCode = 2;
    } else {
        const activation = resolveDebugActivation(workspace);
        if (activation) {
            process.stdout.write(`${activation}\n`);
        }
    }
}

module.exports = { resolveDebugActivation };
