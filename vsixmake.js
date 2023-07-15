const { execSync } = require('child_process');
const fs = require('fs');
const fspath = require('path');

const PACKAGE_PATH = './package.json';
const SAVE_FOLDER = 'dist';
const WEBPACK_OUT_FOLDER = 'out';

function readJSON(path) {
    const context = fs.readFileSync(path, 'utf-8');
    return JSON.parse(context);
}


function writeJSON(path, obj) {
    const jsonString = JSON.stringify(obj, null, '\t');
    fs.writeFileSync(path, jsonString);
}

function changeMain(path) {
    const packageJS = readJSON(PACKAGE_PATH);
    packageJS.main = path;
    writeJSON(PACKAGE_PATH, packageJS);
}

function findVsix() {
    for (const file of fs.readdirSync(__dirname)) {
        if (file.endsWith('.vsix') && file.includes('digital-ide')) {
            return file;
        }
    }
    return null;
}

if (!fs.existsSync(SAVE_FOLDER)) {
    fs.mkdirSync(SAVE_FOLDER);
}

changeMain('./out/extension');
execSync('vsce package');
changeMain('./src/extension');

// remove orginal digital ide
execSync('code --uninstall-extension sterben.digital-ide');

const vsix = findVsix();
const targetPath = fspath.join(SAVE_FOLDER, vsix);
fs.copyFileSync(vsix, targetPath);
fs.unlinkSync(vsix);
fs.rm(WEBPACK_OUT_FOLDER, { recursive: true, force: true }, () => {});

const vsixPath = fspath.join(SAVE_FOLDER, vsix);
// install new one
execSync('code --install-extension ' + vsixPath);