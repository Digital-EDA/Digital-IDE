const crypto = require('crypto');
const fs = require('fs');
const path = require('path');

const pluginRoot = path.resolve(__dirname, '..');
const webuiRoot = path.resolve(pluginRoot, '..', 'webui', 'wave');
const distRoot = path.join(webuiRoot, 'dist');
const publishRoot = path.join(pluginRoot, 'resources', 'waveform');
const manifestPath = path.join(pluginRoot, 'resources', 'waveform-build-manifest.json');
const checkOnly = process.argv.includes('--check');

function filesBelow(root) {
    const result = [];
    const pending = [''];
    while (pending.length > 0) {
        const relative = pending.pop();
        const absolute = path.join(root, relative);
        for (const entry of fs.readdirSync(absolute, { withFileTypes: true })) {
            const child = path.join(relative, entry.name);
            if (entry.isDirectory()) {
                pending.push(child);
            } else if (entry.isFile()) {
                result.push(child.split(path.sep).join('/'));
            }
        }
    }
    return result.sort();
}

function digestFiles(root, files) {
    const hash = crypto.createHash('sha256');
    for (const relative of files) {
        hash.update(relative, 'utf8');
        hash.update('\0');
        hash.update(fs.readFileSync(path.join(root, relative)));
        hash.update('\0');
    }
    return hash.digest('hex');
}

function digestTree(root) {
    if (!fs.existsSync(root)) throw new Error(`required directory is missing: ${root}`);
    const files = filesBelow(root);
    return { files, digest: digestFiles(root, files) };
}

function sourceManifest() {
    const roots = ['src', 'tests'];
    const files = [
        'index.html',
        'package.json',
        'package-lock.json',
        'tsconfig.json',
        'tsconfig.node.json',
        'vite.config.ts',
    ];
    for (const root of roots) {
        files.push(...filesBelow(path.join(webuiRoot, root)).map(file => `${root}/${file}`));
    }
    files.sort();
    return { files, digest: digestFiles(webuiRoot, files) };
}

function expectedManifest() {
    const source = sourceManifest();
    const dist = digestTree(distRoot);
    return {
        schemaVersion: 1,
        sourceRoot: 'webui/wave',
        sourceSha256: source.digest,
        packageLockSha256: crypto.createHash('sha256')
            .update(fs.readFileSync(path.join(webuiRoot, 'package-lock.json')))
            .digest('hex'),
        distSha256: dist.digest,
        distFiles: dist.files,
    };
}

function fail(message) {
    process.stderr.write(`waveform publish check failed: ${message}\n`);
    process.exit(1);
}

if (!fs.existsSync(path.join(distRoot, 'index.html'))) {
    fail(`WebUI dist is missing; build ${webuiRoot} first`);
}

const expected = expectedManifest();
if (checkOnly) {
    if (!fs.existsSync(manifestPath) || !fs.existsSync(publishRoot)) {
        fail('published resources or build manifest are missing');
    }
    const actualManifest = JSON.parse(fs.readFileSync(manifestPath, 'utf8'));
    if (JSON.stringify(actualManifest) !== JSON.stringify(expected)) {
        fail('build manifest does not match the current WebUI source and dist');
    }
    const published = digestTree(publishRoot);
    if (published.digest !== expected.distSha256
        || JSON.stringify(published.files) !== JSON.stringify(expected.distFiles)) {
        fail('plugin resources are not a byte-identical WebUI dist publication');
    }
    process.stdout.write(`WAVEFORM_PUBLISH_PASS ${expected.distSha256}\n`);
} else {
    fs.rmSync(publishRoot, { recursive: true, force: true });
    fs.mkdirSync(path.dirname(publishRoot), { recursive: true });
    fs.cpSync(distRoot, publishRoot, { recursive: true });
    fs.writeFileSync(manifestPath, `${JSON.stringify(expected, null, 2)}\n`, 'utf8');
    process.stdout.write(`WAVEFORM_PUBLISHED ${expected.distSha256}\n`);
}
