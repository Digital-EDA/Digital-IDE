const vscode = require('vscode');

const fs = require('fs');

const hdlParser = require('./parser');
const { exit } = require('process');

const githubIssueUrl = 'https://github.com/Digital-EDA/Digital-IDE/issues';
const extensionUrl = 'https://github.com/Digital-EDA/Digital-IDE';

const _hdlParser = {
    module: null,
    tempPath: '/home/hdl_parser',

    async acquire() {
        const module = this.module;
        if (module) {
            return module;
        } else {
            const _m = await hdlParser();
            this.module = _m;
            return _m;
        }
    }
};

const debug = {
    acquire: 0,
    io: 0,
    compute: 0
};

async function callParser(path, func) {
    const s1 = Date.now();
    const wasmModule = await _hdlParser.acquire();
    debug.acquire += Date.now() - s1;

    const file = _hdlParser.tempPath;
    const fileLength = file.length;

    const s2 = Date.now();
    const source = fs.readFileSync(path, 'utf-8') + '\n';
    wasmModule.FS.writeFile(_hdlParser.tempPath, source, { encoding: 'utf8' });
    debug.io += Date.now() - s2;
    
    try {
        const s3 = Date.now();
        const res = wasmModule.ccall('call_parser', 'string', ['string', 'int', 'int'], [file, fileLength, func]);
        debug.compute += Date.now() - s3;
        console.log(path, debug);
        return JSON.parse(res);
    } catch (error) {
        console.log(`errors happen when call wasm, path: ${path}, errors: ${error}, input params: (${path}, ${func})`);

        const dsaSetting = vscode.workspace.getConfiguration('digital-ide.dont-show-again');
        if (dsaSetting.get('propose.issue', false) === true) {
            return undefined;
        }
        const res = await vscode.window.showErrorMessage(
            `Errors happen when parsing ${path}. Error: "${error}". Just propose a valuable issue in our github repo 😊`,
            { title: 'Go and Propose!', value: true },
            { title: "Don't Show Again", value: false }
        );
        if (res && res.value === true) {
            vscode.env.openExternal(vscode.Uri.parse(githubIssueUrl));
        } else if (res && res.value === false) {
            dsaSetting.update('propose.issue', true);
        }

        return undefined;
    }
}


async function vhdlFast(path) {
    return await callParser(path, 1);
}

async function vhdlAll(path) {
    return await callParser(path, 2);
}

async function svFast(path) {
    return await callParser(path, 3);
}

async function svAll(path) {
    return await callParser(path, 4);
}

async function vlogFast(path) {
    return await callParser(path, 5);
}

async function vlogAll(path) {
    return await callParser(path, 6);
}

module.exports = {
    vlogFast,
    vlogAll,
    vhdlFast,
    vhdlAll,
    svFast,
    svAll,
    extensionUrl,
    callParser
};