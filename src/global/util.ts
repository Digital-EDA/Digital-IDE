import * as fs from 'fs';
import * as vscode from 'vscode';
import * as childProcess from 'child_process';

import { AbsPath } from ".";

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
 * tell if two set are element-wise equal
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

