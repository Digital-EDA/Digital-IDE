/* eslint-disable @typescript-eslint/naming-convention */
const fs = require('fs');
const fspath = require('path');

const { vlogFast } = require('./resources/hdlParser');

const COMMON_PATH = fspath.resolve('./lib/common/Driver');

const TEST_FILE = './parser_stuck.v';
const TEST_FILE2 = './src/test/vlog/dependence_test/parent.v';
const TEST_FILE3 = './src/test/vlog/formatter_test.v';


function isFile(path) {
    if (!fs.existsSync(path)) {
        return false;
    }
    const state = fs.statSync(path);
    if (state.isDirectory()) {
        return false;
    }
    return true;
}

/**
 * judge if the path represent a Dir
 * @param path
 * @returns
 */
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

function* walk(path, condition) {
    if (isFile(path)) {
        if (!condition || condition(path)) {
            yield path;
        }
    }
    else {
        for (const file of fs.readdirSync(path)) {
            const filePath = fspath.join(path, file);
            if (isDir(filePath)) {
                for (const targetPath of walk(filePath, condition)) {
                    yield targetPath;
                }
            }
            else if (isFile(filePath)) {
                if (!condition || condition(filePath)) {
                    yield filePath;
                }
            }
        }
    }
}

(async() => {
    console.time('test');
    // await vlogFast('./lib/common/Apply/DSP/Advance/FFT/Flow_FFT_IFFT/BF_op.v');
    for (const file of walk('./src/test/vlog/dependence_test', f => f.endsWith('.v'))) {
        console.log('[file] ', file);
        try {
            const res = await vlogFast(file);
            console.log(res);
        } catch (err) {
            console.log(err);
        }
    }
    console.timeEnd('test');
})();