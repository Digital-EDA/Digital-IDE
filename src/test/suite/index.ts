import * as fs from 'fs';
import * as path from 'path';
import Mocha = require('mocha');

export function run(): Promise<void> {
    const mocha = new Mocha({
        color: true,
        grep: process.env.DIGITAL_VSCODE_TEST_GREP,
        timeout: 60_000,
        ui: 'tdd',
    });

    for (const file of fs.readdirSync(__dirname).sort()) {
        if (file.endsWith('.test.js')) {
            mocha.addFile(path.join(__dirname, file));
        }
    }

    return new Promise((resolve, reject) => {
        mocha.run((failures: number) => {
            if (failures > 0) {
                reject(new Error(`${failures} VS Code test(s) failed`));
            } else {
                resolve();
            }
        });
    });
}
