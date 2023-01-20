const { execSync } = require('child_process');
const fs = require('fs');
const path = require('path');
const HDLFile = require('./src/HDLfilesys/operation/files');
const HDLPath = require('./src/HDLfilesys/operation/path');

const PACKAGE_PATH = './package.json';
const SAVE_FOLDER = 'dist';
const WEBPACK_OUT_FOLDER = 'out';

function changeMain(path) {
    const packageJS = HDLFile.pullJsonInfo(PACKAGE_PATH);
    packageJS.main = path;
    HDLFile.pushJsonInfo(PACKAGE_PATH, packageJS);
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
const targetPath = path.join(SAVE_FOLDER, vsix);
HDLFile.moveFile(vsix, targetPath, true);
HDLPath.deleteFolder(WEBPACK_OUT_FOLDER);

const vsixPath = HDLPath.join(SAVE_FOLDER, vsix);
// install new one
execSync('code --install-extension ' + vsixPath);