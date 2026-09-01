const fs = require('fs');
const path = require('path');

const fixtureRoot = path.resolve(__dirname, '../test-fixtures/workspace/src/sv');
const e2ePath = path.resolve(__dirname, '../src/test/suite/netlist.test.ts');
const commandPath = path.resolve(__dirname, '../src/netlist/commands.ts');
const webuiRoot = path.resolve(__dirname, '../../webui/netlist');
const webuiManifestPath = path.join(webuiRoot, 'public/test/manifest.json');
const webuiBrowserTestPath = path.join(webuiRoot, 'tests/browser-smoke.mjs');
const packagePath = path.resolve(__dirname, '../package.json');
const required = [
    'adversarial.sv',
    'congestion.sv',
    'constraint_conflict.sv',
    'fanout.sv',
    'hierarchy.sv',
    'incremental.sv',
    'randomized.sv',
];

const missing = required.filter(name => !fs.existsSync(path.join(fixtureRoot, name)));
if (missing.length > 0) {
    throw new Error(`Netlist SV fixture matrix is incomplete: ${missing.join(', ')}`);
}

const read = name => fs.readFileSync(path.join(fixtureRoot, name), 'utf8');
const requireCount = (name, pattern, expected, label) => {
    const count = read(name).match(pattern)?.length ?? 0;
    if (count !== expected) {
        throw new Error(`${name} must contain ${expected} ${label}, found ${count}`);
    }
};
const requirePattern = (name, pattern, label) => {
    if (!pattern.test(read(name))) {
        throw new Error(`${name} does not encode ${label}`);
    }
};

requireCount(
    'hierarchy.sv',
    /\bmodule\s+hierarchy(?:_level_\d+)?\b/g,
    32,
    'hierarchy levels',
);
requirePattern('congestion.sv', /index\s*<\s*48/, '48 parallel paths');
requireCount('fanout.sv', /output\s+logic\s+y\d\d/g, 64, 'scalar fanout targets');
requireCount('fanout.sv', /assign\s+y\d\d\s*=\s*source/g, 64, 'fanout assignments');
requireCount('randomized.sv', /assign\s+y_[0-9a-f]+\s*=\s*~a_[0-9a-f]+/g, 24, 'seeded paths');
requirePattern('incremental.sv', /assign\s+y1\s*=\s*1'b0/, 'the incremental edit anchor');
requirePattern(
    'constraint_conflict.sv',
    /\.i0\(lower\),\s*\.i1\(upper\)/,
    'crossed anchor equalities',
);
requirePattern('adversarial.sv', /\)\s*\n\s*assign\s+y/, 'a malformed module header');

const e2e = fs.readFileSync(e2ePath, 'utf8');
for (const marker of [
    'response.jsonPath',
    'response.render, undefined',
    'bootstrapHasYosys',
    'netloom-reference',
    'netloom_semantic_bg.wasm',
    'netloom-elk.wasm',
    'avoid.wasm',
    '.net-route-arc',
    'runtimeErrors',
    'canvasBackground',
    "'wasm-unsafe-eval'",
]) {
    if (!e2e.includes(marker)) {
        throw new Error(`Netlist Webview E2E contract is missing ${marker}`);
    }
}

const commands = fs.readFileSync(commandPath, 'utf8');
for (const marker of ['readYosysJson(response)', 'protocolVersion: 2', 'yosysJson: input.yosysJson']) {
    if (!commands.includes(marker)) {
        throw new Error(`Netlist plugin command contract is missing ${marker}`);
    }
}
if (commands.includes('acceptedRender(response.render)')) {
    throw new Error('Netlist plugin still depends on Rust AcceptedRenderIr');
}

const webuiManifest = JSON.parse(fs.readFileSync(webuiManifestPath, 'utf8'));
if (webuiManifest.version !== 1
    || !Array.isArray(webuiManifest.cases)
    || webuiManifest.cases.length !== 14) {
    throw new Error('Reference WebUI manifest must contain the 14 accepted JSON/module cases');
}
const webuiBrowserTest = fs.readFileSync(webuiBrowserTestPath, 'utf8');
for (const marker of ['auditAllFixtures', 'fixtures.length, 14', '35 checks', 'failedRequests']) {
    if (!webuiBrowserTest.includes(marker)) {
        throw new Error(`Reference WebUI browser gate is missing ${marker}`);
    }
}

const packageJson = JSON.parse(fs.readFileSync(packagePath, 'utf8'));
const webviewGate = packageJson.scripts?.['test:netlist-webui'];
if (typeof webviewGate !== 'string'
    || !webviewGate.startsWith('npm run check:netlist-fixtures &&')
    || !webviewGate.includes('--grep "Netlist Webview integration"')) {
    throw new Error('test:netlist-webui does not enforce the fixture gate before the real Webview E2E');
}

process.stdout.write(`NETLIST_WEBVIEW_FIXTURE_GATE_PASS ${webuiManifest.cases.length}\n`);
