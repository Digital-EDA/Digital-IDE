import * as fs from 'fs';
import * as os from 'os';
import * as vscode from 'vscode';
import * as childProcess from 'child_process';

import { AbsPath, MainOutput } from ".";
import { t } from '../i18n';

export class PathSet {
    files: Set<AbsPath> = new Set<AbsPath>();
    add(path: AbsPath) {
        this.files.add(path);
    }
    checkAdd(path: AbsPath | AbsPath[]) {
        if (path instanceof Array) {
            path.forEach(p => this.checkAdd(p));
        } else if (fs.existsSync(path)) {
            this.files.add(path);
        }
    }
}

/**
 * @description 判断两个集合是否逐元素相同
 * @param setA 
 * @param setB 
 */
export function isSameSet<T>(setA: Set<T>, setB: Set<T>): boolean {
    if (setA.size !== setB.size) {
        return false;
    }
    
    for (const el of setB) {
        if (!setA.has(el)) {
            return false;
        }
    }
    return true;
}

interface ExecutorOutput {
    stdout: string
    stderr: string
}

/**
 * more elegant function to execute command
 * @param executor executor
 * @param args argruments
 * @returns { Promise<ExecutorOutput> }
 */
export async function easyExec(executor: string, args: string[]): Promise<ExecutorOutput> {
    const allArguments = [executor, ...args];
    const command = allArguments.join(' ');

    const p = new Promise<ExecutorOutput>( ( resolve, _ ) => {
        childProcess.exec(command, ( _, stdout, stderr ) => {
            resolve({ stdout, stderr });
        });
    });

    return p;
}

/**
 * Tracks all webviews.
 */
export class WebviewCollection {
	private readonly _webviews = new Set<{
		readonly resource: string;
		readonly webviewPanel: vscode.WebviewPanel;
	}>();

	/**
	 * Get all known webviews for a given uri.
	 */
	public *get(uri: vscode.Uri): Iterable<vscode.WebviewPanel> {
		const key = uri.toString();
		for (const entry of this._webviews) {
			if (entry.resource === key) {
				yield entry.webviewPanel;
			}
		}
	}

	/**
	 * Add a new webview to the collection.
	 */
	public add(uri: vscode.Uri, webviewPanel: vscode.WebviewPanel) {
		const entry = { resource: uri.toString(), webviewPanel };
		this._webviews.add(entry);

		webviewPanel.onDidDispose(() => {
			this._webviews.delete(entry);
		});
	}
}


export function replacePlaceholders(template: string, ...args: string[]): string {
    return template.replace(/\$(\d+)/g, (match, p1) => {
        const index = parseInt(p1, 10) - 1;
        return args[index] !== undefined ? args[index] : match;
    });
}

export function debounce(fn: (...args: any[]) => any, timeout: number) {
    let timer: NodeJS.Timeout | undefined = undefined;

    return (...args: any[]) => {
        if (timer) {
            clearTimeout(timer);
        }
        timer = setTimeout(() => {
            fn(...args);
        }, timeout);
    };
}

/**
 * @description 平台签名
 */
export enum IPlatformSignature {
    x86Windows = 'windows_amd64',
    aach64Windows = 'windows_aarch64',
    x86Darwin = 'darwin_amd64',
    aarch64Darwin = 'darwin_aarch64',
    x86Linux = 'linux_amd64',
    aarch64Linux = 'linux_aarch64',
    unsupport = 'unsupport'
};

/**
 * @description 获取平台签名
 */
export function getPlatformPlatformSignature(): IPlatformSignature {
    // Possible values are `'arm'`, `'arm64'`, `'ia32'`, `'mips'`,`'mipsel'`, `'ppc'`, `'ppc64'`, `'s390'`, `'s390x'`, `'x32'`, and `'x64'`
    const arch = os.arch();

    // Possible values are `'aix'`, `'darwin'`, `'freebsd'`,`'linux'`, `'openbsd'`, `'sunos'`, and `'win32'`.
    const osName = os.platform();

    switch (arch) {
        case 'arm':
        case 'arm64':
            switch (osName) {
                case 'win32': return IPlatformSignature.aach64Windows;
                case 'darwin': return IPlatformSignature.aarch64Darwin;
                case 'linux': return IPlatformSignature.aarch64Linux;
                default: return IPlatformSignature.unsupport;
            }
        
        case 'x32':
        case 'x64':
            switch (osName) {
                case 'win32': return IPlatformSignature.x86Windows;
                case 'darwin': return IPlatformSignature.x86Darwin;
                case 'linux': return IPlatformSignature.x86Linux;
                default: return IPlatformSignature.unsupport;
            }
    
        default: return IPlatformSignature.unsupport;
    }
}

/**
 * @description 获取包含 {name} 的所有 pid
 * @returns 
 */
export function getPIDsWithName(name: string): Promise<number[]> {
    return new Promise((resolve, reject) => {
        let command: string;
        let parseOutput: (output: string) => number[];

        const currentPlatform = os.platform();
        if (currentPlatform === 'win32') {
            // Windows 使用 tasklist 命令
            command = `tasklist /FI "IMAGENAME eq ${name}*" /FO CSV /NH`;
            parseOutput = (output: string) => {
                return output
                    .split('\n')
                    .filter(line => line.includes(name))
                    .map(line => {
                        const [imageName, pid] = line.split('","');
                        return parseInt(pid.replace(/"/g, ''), 10);
                    });
            };
        } else {
            // macOS 和 Linux 使用 ps 命令
            command = 'ps -e -o pid,comm=';
            parseOutput = (output: string) => {
                return output
                    .split('\n')
                    .filter(line => line.includes(name))
                    .map(line => {
                        const [pid] = line.trim().split(' ');
                        return parseInt(pid, 10);
                    });
            };
        }

        // 执行命令
        childProcess.exec(command, (error, stdout, stderr) => {
            if (error) {
                reject(`Error: ${error.message}`);
                return;
            }

            if (stderr) {
                reject(`Stderr: ${stderr}`);
                return;
            }

            // 解析输出并返回进程号
            const processes = parseOutput(stdout);
            resolve(processes);
        });
    });
}

export function killProcess(pid: number): Promise<void> {
    return new Promise((resolve, reject) => {
        let command: string;

        const currentPlatform = os.platform();

        if (currentPlatform === 'win32') {
            // Windows 使用 taskkill 命令
            command = `taskkill /PID ${pid} /F`;
        } else {
            // macOS 和 Linux 使用 kill 命令
            command = `kill -9 ${pid}`;
        }

        // 执行命令
        childProcess.exec(command, (error, stdout, stderr) => {
            if (error) {
                reject(`Error: ${error.message}`);
                return;
            }

            if (stderr) {
                reject(`Stderr: ${stderr}`);
                return;
            }
            const message = t('info.process-killed', pid.toString());
            
            MainOutput.report(message);
            console.log(message);
            
            resolve();
        });
    });
}