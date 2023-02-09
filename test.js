/* eslint-disable @typescript-eslint/naming-convention */
const fs = require('fs');
const path = require('path');

const sysvlog_build = require('./wasm/hdlParser/parser');

const COMMON_PATH = path.resolve('./lib/common/Driver');

const TEST_FILE = './parser_stuck.v';
const TEST_FILE2 = './src/test/vlog/dependence_test/parent.v';
const TEST_FILE3 = './src/test/vlog/formatter_test.v';

function isDir(path) {
    if (!fs.existsSync(path)) {
        return false;
    }

    const state = fs.statSync(path);
    if (state.isDirectory()) {
        return true;
    }
    return false;
}

function getHDLFiles(path) {
    if (isDir(path)) {
        const hdlFiles = [];
        for (const file of fs.readdirSync(path)) {
            const filePath = path + '/' + file;
            if (isDir(filePath)) {
                const subHdlFiles = getHDLFiles(filePath);
                if (subHdlFiles.length > 0) {
                    hdlFiles.push(...subHdlFiles);
                }
            } else if (filePath.endsWith('.v')) {
                hdlFiles.push(filePath);
            }
        }
        return hdlFiles;
    } else if (path.endsWith('.v')) {
        return [path];
    } else {
        return [];
    }
}

(async() => {
    const Module = await sysvlog_build();
    console.log(Object.keys(Module).filter(name => name.startsWith('_') && !name.startsWith('__')));
    const source = fs.readFileSync(TEST_FILE2, 'utf-8') + '\n';
    Module.FS.writeFile('/sysvlog_build', source, { encoding: 'utf8' });    

    const start = Date.now();

    const fast = Module.ccall('vlog_fast', 'string', ['string'], ['/sysvlog_build']);
    const costTime = (Date.now() - start) / 1000;
    console.log(JSON.stringify(JSON.parse(fast), null, '  '));
    console.log('cost time', costTime);
})();