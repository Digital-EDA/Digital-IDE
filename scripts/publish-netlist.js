const crypto = require('crypto');
const fs = require('fs');
const path = require('path');

const pluginRoot = path.resolve(__dirname, '..');
const serverRoot = path.resolve(pluginRoot, '..');
const webuiRoot = path.join(serverRoot, 'webui', 'netlist');
const distRoot = path.join(webuiRoot, 'dist');
const publishRoot = path.join(pluginRoot, 'resources', 'netlist');
const manifestPath = path.join(pluginRoot, 'resources', 'netlist-build-manifest.json');
const rendererWasm = {
    semantic: path.join(webuiRoot, 'public', 'vendor', 'netloom-semantic', 'netloom_semantic_bg.wasm'),
    placement: path.join(webuiRoot, 'public', 'vendor', 'netloom', 'netloom-elk.wasm'),
    routing: path.join(webuiRoot, 'public', 'vendor', 'avoid', 'avoid.wasm'),
};
const checkOnly = process.argv.includes('--check');

function filesBelow(root) {
    const result = [];
    const pending = [''];
    while (pending.length > 0) {
        const relative = pending.pop();
        const absolute = path.join(root, relative);
        for (const entry of fs.readdirSync(absolute, { withFileTypes: true })) {
            const child = path.join(relative, entry.name);
            if (entry.isDirectory()) pending.push(child);
            else if (entry.isFile()) result.push(child.split(path.sep).join('/'));
        }
    }
    return result.sort();
}

function sha256File(file) {
    return crypto.createHash('sha256').update(fs.readFileSync(file)).digest('hex');
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
    const files = ['index.html', 'package.json', 'package-lock.json', 'vite.config.js'];
    for (const root of ['public', 'scripts', 'src', 'tests']) {
        files.push(...filesBelow(path.join(webuiRoot, root)).map(file => `${root}/${file}`));
    }
    files.sort();
    return { files, digest: digestFiles(webuiRoot, files) };
}

function skinManifest() {
    const root = path.join(webuiRoot, 'public', 'design', 'dide');
    const catalogPath = path.join(root, 'skin-index.json');
    const catalog = JSON.parse(fs.readFileSync(catalogPath, 'utf8'));
    const names = Object.keys(catalog.skins || {}).sort();
    if (catalog.version !== 1 || catalog.count !== names.length || names.length === 0) {
        throw new Error('DIDE skin catalog count or version is invalid');
    }
    for (const name of names) {
        const relative = catalog.skins[name]?.path;
        if (typeof relative !== 'string'
            || relative.includes('\\')
            || path.posix.isAbsolute(relative)
            || relative.split('/').some(segment => !segment || segment === '.' || segment === '..')
            || !relative.endsWith('.svg')
            || !fs.statSync(path.join(root, relative)).isFile()) {
            throw new Error(`DIDE skin ${name} has an invalid asset path`);
        }
    }
    const tree = digestTree(root);
    return { count: names.length, sha256: tree.digest, files: tree.files };
}

function wasmManifest(file) {
    const stat = fs.statSync(file);
    if (!stat.isFile()) throw new Error(`backend WASM is not a file: ${file}`);
    return { sha256: sha256File(file), size: stat.size };
}

function expectedManifest() {
    const source = sourceManifest();
    const dist = digestTree(distRoot);
    return {
        schemaVersion: 1,
        sourceRoot: 'webui/netlist',
        sourceSha256: source.digest,
        packageLockSha256: sha256File(path.join(webuiRoot, 'package-lock.json')),
        distSha256: dist.digest,
        distFiles: dist.files,
        skins: skinManifest(),
        rendererWasm: Object.fromEntries(Object.entries(rendererWasm)
            .map(([name, file]) => [name, wasmManifest(file)])),
    };
}

function fail(message) {
    process.stderr.write(`netlist publish check failed: ${message}\n`);
    process.exit(1);
}

for (const required of [path.join(distRoot, 'index.html'), ...Object.values(rendererWasm)]) {
    if (!fs.existsSync(required)) fail(`required input is missing: ${required}`);
}

const expected = expectedManifest();
if (checkOnly) {
    if (!fs.existsSync(manifestPath) || !fs.existsSync(publishRoot)) {
        fail('published resources or build manifest are missing');
    }
    const actualManifest = JSON.parse(fs.readFileSync(manifestPath, 'utf8'));
    if (JSON.stringify(actualManifest) !== JSON.stringify(expected)) {
        fail('build manifest does not match the current WebUI or backend WASM inputs');
    }
    const published = digestTree(publishRoot);
    if (published.digest !== expected.distSha256
        || JSON.stringify(published.files) !== JSON.stringify(expected.distFiles)) {
        fail('plugin resources are not a byte-identical netlist WebUI publication');
    }
    for (const [name, source] of Object.entries(rendererWasm)) {
        const relative = path.relative(path.join(webuiRoot, 'public'), source);
        const published = path.join(publishRoot, relative);
        if (!fs.existsSync(published)
            || sha256File(published) !== expected.rendererWasm[name].sha256) {
            fail(`published ${name} renderer WASM does not match the signed input`);
        }
    }
    process.stdout.write(`NETLIST_PUBLISH_PASS ${expected.distSha256}\n`);
} else {
    fs.rmSync(publishRoot, { recursive: true, force: true });
    fs.mkdirSync(path.dirname(publishRoot), { recursive: true });
    fs.cpSync(distRoot, publishRoot, { recursive: true });
    fs.writeFileSync(manifestPath, `${JSON.stringify(expected, null, 2)}\n`, 'utf8');
    process.stdout.write(`NETLIST_PUBLISHED ${expected.distSha256}\n`);
}
