'use strict';

const assert = require('assert');
const fs = require('fs');
const os = require('os');
const path = require('path');
const { resolveDebugActivation } = require('./resolve-debug-activation');

function writeFile(file, contents) {
    fs.mkdirSync(path.dirname(file), { recursive: true });
    fs.writeFileSync(file, contents);
}

const temporaryRoot = fs.mkdtempSync(path.join(os.tmpdir(), 'digital-ide-activation-'));
try {
    const workspace = path.join(temporaryRoot, 'workspace');
    writeFile(path.join(workspace, '.vscode', 'property.json'), JSON.stringify({
        arch: {
            hardware: {
                src: '${workspace}/user/src',
                sim: '${workspace}/user/sim',
            },
        },
    }));
    writeFile(path.join(workspace, '.dideignore'), 'user/src/ignored/\nuser/sim/\n');
    writeFile(path.join(workspace, 'outside', 'first.v'), 'module outside; endmodule\n');
    writeFile(path.join(workspace, 'user', 'src', 'ignored', 'first.sv'), 'module ignored; endmodule\n');
    const selected = path.join(workspace, 'user', 'src', 'visible', 'top.sv');
    writeFile(selected, 'module top; endmodule\n');
    writeFile(path.join(workspace, 'user', 'sim', 'tb.sv'), 'module tb; endmodule\n');

    assert.strictEqual(resolveDebugActivation(workspace), fs.realpathSync(selected));
    fs.rmSync(selected);
    assert.strictEqual(resolveDebugActivation(workspace), undefined);
} finally {
    fs.rmSync(temporaryRoot, { recursive: true, force: true });
}
