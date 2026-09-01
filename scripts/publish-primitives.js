const fs = require('fs');
const path = require('path');

const extensionRoot = path.resolve(__dirname, '..');
const serverRoot = path.resolve(extensionRoot, '..');
const sourceRoot = path.join(serverRoot, 'tests', 'factory', 'xilinx', 'primitive');
const targetRoot = path.join(extensionRoot, 'resources', 'primitive', 'xilinx');
const files = ['primitive.bin', 'primitive.json'];
const checkOnly = process.argv.includes('--check');

function fail(message) {
    process.stderr.write(`error: ${message}\n`);
    process.exitCode = 1;
}

for (const file of files) {
    const source = path.join(sourceRoot, file);
    const target = path.join(targetRoot, file);
    if (!fs.existsSync(source) || !fs.statSync(source).isFile()) {
        fail(`Xilinx primitive source is missing: ${source}`);
        continue;
    }
    if (checkOnly) {
        if (!fs.existsSync(target) || !fs.readFileSync(source).equals(fs.readFileSync(target))) {
            fail(`published Xilinx primitive resource differs from ${source}`);
        }
        continue;
    }
    fs.mkdirSync(targetRoot, { recursive: true });
    const temporary = `${target}.tmp`;
    fs.copyFileSync(source, temporary);
    fs.renameSync(temporary, target);
}
