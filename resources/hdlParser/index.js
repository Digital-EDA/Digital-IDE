const hdlParser = require('./parser');
const fs = require('fs');
const { exit } = require('process');

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


async function callParser(path, func) {
    const wasmModule = await _hdlParser.acquire();
    const file = _hdlParser.tempPath;
    const fileLength = file.length;
    const source = fs.readFileSync(path, 'utf-8') + '\n';
    wasmModule.FS.writeFile(_hdlParser.tempPath, source, { encoding: 'utf8' });
    const res = wasmModule.ccall('call_parser', 'string', ['string', 'int', 'int'], [file, fileLength, func]);
    return JSON.parse(res);
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
    svAll
};