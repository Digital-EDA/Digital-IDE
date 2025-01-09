import { parentPort } from 'worker_threads';
import * as childProcess from 'child_process';
import * as fs from 'fs';
import * as os from 'os';

import { WASI } from 'wasi';

type SynthMode = 'before' | 'after' | 'RTL';
type AbsPath = string;

interface SimpleOpe {
    workspacePath: string,
    libCommonPath: string,
    prjPath: string,
    extensionPath: string
}

if (parentPort) {
    parentPort.on('message', message => {
        const command = message.command as string;
        const data = message.data;

        switch (command) {
            case 'open':
                open(data);
                break;
            case 'run':
                run(data);
                break;
            default:
                break;
        }
    });
}

async function open(data: any) {
    const { path, moduleName, mode, filelist, ope } = data;
    const viewer = new Netlist(ope);
    viewer.open(path, moduleName, filelist, mode);
}

async function run(data: any) {
    const { path, ope } = data;
    const viewer = new Netlist(ope);
    viewer.runYs(path);
}

function getDiskLetters(): Promise<string[]> {
    return new Promise((resolve, reject) => {
        // 调用 wmic 命令获取磁盘信息
        childProcess.exec('wmic logicaldisk get name', (error, stdout, stderr) => {
            if (error) {
                reject(`Error: ${error.message}`);
                return;
            }

            if (stderr) {
                reject(`Stderr: ${stderr}`);
                return;
            }

            // 解析命令输出
            const disks = stdout
                .split('\n') // 按行分割
                .map(line => line.trim()) // 去除每行的空白字符
                .filter(line => /^[A-Z]:$/.test(line)); // 过滤出盘符（如 C:, D:）

            resolve(disks);
        });
    });
}

function mkdir(path: AbsPath): boolean {
    if (!path) {
        return false;
    }
    // 如果存在则直接退出
    if (fs.existsSync(path)) {
        return true;
    }

    try {
        fs.mkdirSync(path, {recursive:true});
        return true;
    } 
    catch (error) {
        fs.mkdirSync(path, {recursive:true});
    }
    return false;
}

function join(...paths: string[]): AbsPath {
    return paths.join('/');
}

function isVlog(file: AbsPath): boolean {
    const exts = ['.v', '.vh', '.vl', '.sv'];
    for (const ext of exts) {
        if (file.toLowerCase().endsWith(ext)) {
            return true;
        }
    }
    return false;
}

class Netlist {
    wsName: string;
    libName: string;
    ope: SimpleOpe;
    wasm?: WebAssembly.Module;

    constructor(ope: SimpleOpe) {
        this.wsName = '{workspace}';
        this.libName = '{library}';
        this.ope = ope;
    }

    public async open(path: string, moduleName: string, filelist: AbsPath[], mode: SynthMode) {

        if (!this.wasm) {
            const wasm = await this.loadWasm();
            this.wasm = wasm;
        }

        const targetYs = this.makeYs(filelist, moduleName, mode);
        if (!targetYs || !this.wasm) {
            return;
        }

        const wasm = this.wasm;
        const wasiResult = await this.makeWasi(targetYs, moduleName);
        
        if (wasiResult === undefined) {
            return;
        }
        const { wasi, fd } = wasiResult;

        const netlistPayloadFolder = join(this.ope.prjPath, 'netlist');
        const targetJson = join(netlistPayloadFolder, moduleName + '.json');
        if (fs.existsSync(targetJson)) {
            fs.rmSync(targetJson);
        }

        const instance = await WebAssembly.instantiate(wasm, {
            wasi_snapshot_preview1: wasi.wasiImport
        });
        
        try {
            const exitCode = wasi.start(instance);            
        } catch (error) {
            if (parentPort) {
                parentPort.postMessage({
                    command: 'finish',
                    data: { error }
                });
            }
        }

        if (!fs.existsSync(targetJson)) {
            fs.closeSync(fd);
            const logFilePath = join(this.ope.prjPath, 'netlist', moduleName + '.log');
            if (parentPort) {
                parentPort.postMessage({
                    command: 'error-log-file',
                    data: { logFilePath }
                });
            }
        }

        if (parentPort) {
            parentPort.postMessage({
                command: 'finish',
                data: {}
            });
        }
    }

    private makeYs(files: AbsPath[], topModule: string, mode: SynthMode) {
        const netlistPayloadFolder = join(this.ope.prjPath, 'netlist');
        mkdir(netlistPayloadFolder);
        const target = join(netlistPayloadFolder, topModule + '.ys');
        const targetJson = join(netlistPayloadFolder, topModule + '.json').replace(this.ope.workspacePath, this.wsName);

        const scripts: string[] = [];
        
        for (const file of files) {
            if (!isVlog(file)) {
                return undefined;
            }

            if (file.startsWith(this.ope.workspacePath)) {
                const constraintPath = file.replace(this.ope.workspacePath, this.wsName);
                scripts.push(`read_verilog -sv -formal -overwrite ${constraintPath}`);
            } else if (file.startsWith(this.ope.libCommonPath)) {
                const constraintPath = file.replace(this.ope.libCommonPath, this.libName);
                scripts.push(`read_verilog -sv -formal -overwrite ${constraintPath}`);
            }
        }

        switch (mode) {
        case 'before':
            scripts.push('design -reset-vlog; proc;');
            break;
        case 'after':
            scripts.push('design -reset-vlog; proc; opt_clean;');
            break;
        case 'RTL':
            scripts.push('synth -run coarse;');
            break;
        }
        scripts.push(`write_json ${targetJson}`);
        const ysCode = scripts.join('\n');
        fs.writeFileSync(target, ysCode, { encoding: 'utf-8' });
        return target.replace(this.ope.workspacePath, this.wsName);
    }

    public async getPreopens() {
        const basepreopens = {
            '/share': join(this.ope.extensionPath, 'resources', 'dide-netlist', 'static', 'share'),
            [this.wsName ]: this.ope.workspacePath,
            [this.libName]: this.ope.libCommonPath
        };
        if (os.platform() === 'win32') {
            const mounts = await getDiskLetters();
            for (const mountName of mounts) {
                const realMount = mountName + '/';
                basepreopens[realMount.toLowerCase()] = realMount;
                basepreopens[realMount.toUpperCase()] = realMount;
            }
        } else {
            basepreopens['/'] = '/';
        }
        return basepreopens;
    }

    private async makeWasi(target: string, logName: string) {
        // 创建日志文件路径
        const logFilePath = join(this.ope.prjPath, 'netlist', logName + '.log');
        if (fs.existsSync(logFilePath)) {
            fs.rmSync(logFilePath)
        }
        const logFd = fs.openSync(logFilePath, 'a');

        try {
            const wasiOption = {
                version: 'preview1',
                args: [
                    'yosys',
                    '-s',
                    target
                ],
                preopens: await this.getPreopens(),
                stdin: process.stdin.fd,
                stdout: process.stdout.fd,
                stderr: logFd,
                env: process.env
            };

            const wasi = new WASI(wasiOption);
            return { wasi, fd: logFd };
        } catch (error) {
            fs.closeSync(logFd);
            return undefined;
        }
    }

    private async loadWasm() {
        const netlistWasmPath = join(this.ope.extensionPath, 'resources', 'dide-netlist', 'static', 'yosys.wasm');
        const binary = fs.readFileSync(netlistWasmPath);
        const wasm = await WebAssembly.compile(binary);
        return wasm;
    }

    public getJsonPathFromYs(path: AbsPath): AbsPath | undefined {
        for (const line of fs.readFileSync(path, { encoding: 'utf-8' }).split('\n')) {
            if (line.trim().startsWith('write_json')) {
                const path = line.split(/\s+/).at(1);
                if (path) {
                    const realPath = path
                        .replace(this.wsName, this.ope.workspacePath)
                        .replace(this.libName, this.ope.libCommonPath);
                    return realPath.replace(/\\/g,"\/");
                }
            }
        }
        return undefined;
    }

    public async runYs(path: string) {
        const ysPath = path.replace(/\\/g,"\/");
        const targetJson = this.getJsonPathFromYs(ysPath);
        const name = ysPath.split('/').at(-1) as string;
        const wasiResult = await this.makeWasi(ysPath, name);
        
        if (wasiResult === undefined) {
            return;
        }
        const { wasi, fd } = wasiResult;

        if (targetJson && fs.existsSync(targetJson)) {
            fs.rmSync(targetJson);
        }

        if (!this.wasm) {
            const wasm = await this.loadWasm();
            this.wasm = wasm;
        }
        const wasm = this.wasm;

        const instance = await WebAssembly.instantiate(wasm, {
            wasi_snapshot_preview1: wasi.wasiImport
        });

        try {
            const exitCode = wasi.start(instance);
        } catch (error) {
            if (parentPort) {
                parentPort.postMessage({
                    command: 'finish',
                    data: { error }
                });
            }
        }

        if (targetJson && !fs.existsSync(targetJson)) {
            fs.closeSync(fd);
            const logFilePath = join(this.ope.prjPath, 'netlist', name + '.log');
            if (parentPort) {
                parentPort.postMessage({
                    command: 'error-log-file',
                    data: { logFilePath }
                });
            }
        }

        if (parentPort) {
            parentPort.postMessage({
                command: 'finish',
                data: {}
            });
        }
    }
}