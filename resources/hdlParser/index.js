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

async function vlogFast(path) {
    if (!fs.existsSync(path)) {
        return undefined;
    }
    const wasmModule = await _hdlParser.acquire();
    const source = fs.readFileSync(path, 'utf-8') + '\n';
    wasmModule.FS.writeFile(_hdlParser.tempPath, source, { encoding: 'utf8' });
    const res = wasmModule.ccall('vlog_fast', 'string', ['string'], [_hdlParser.tempPath]);
    try {
        return JSON.parse(res);
    } catch (err) {
        console.log(res);
        fs.writeFileSync('./draft.json', res);
        console.log('error happen when parse ' + path);
        console.log(err);
        exit(-1);
    }
}

async function vlogAll(path) {
    if (!fs.existsSync(path)) {
        return undefined;
    }
    const wasmModule = await _hdlParser.acquire();
    const source = fs.readFileSync(path, 'utf-8') + '\n';
    wasmModule.FS.writeFile(_hdlParser.tempPath, source, { encoding: 'utf8' });
    const res = wasmModule.ccall('vlog_all', 'string', ['string'], [_hdlParser.tempPath]);
    return JSON.parse(res);
}

async function vhdlFast(path) {
    if (!fs.existsSync(path)) {
        return undefined;
    }
    return {};
}

async function vhdlAll(path) {
    if (!fs.existsSync(path)) {
        return undefined;
    }
    return {};
}

async function svFast(path) {
    if (!fs.existsSync(path)) {
        return undefined;
    }
    return {};
}

async function svAll(path) {
    if (!fs.existsSync(path)) {
        return undefined;
    }
    return {};
}

module.exports = {
    vlogFast,
    vlogAll,
    vhdlFast,
    vhdlAll,
    svFast,
    svAll
};