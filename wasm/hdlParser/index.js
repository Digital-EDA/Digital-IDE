const hdlParser = require('./parser');

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
    const wasmModule = await _hdlParser.acquire();
    const source = fs.readFileSync(path, 'utf-8');
    wasmModule.FS.writeFile(_hdlParser.tempPath, source, { encoding: 'utf8' });
    const res = wasmModule.ccall('vlog_fast', 'string', ['string'], [_hdlParser.tempPath]);
    return JSON.parse(res);
}

async function vlogAll(path) {
    const wasmModule = await _hdlParser.acquire();
    const source = fs.readFileSync(path, 'utf-8');
    wasmModule.FS.writeFile(_hdlParser.tempPath, source, { encoding: 'utf8' });
    const res = wasmModule.ccall('vlog_all', 'string', ['string'], [_hdlParser.tempPath]);
    return JSON.parse(res);
}

module.exports = {
    vlogFast,
    vlogAll
};