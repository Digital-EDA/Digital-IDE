import * as vscode from 'vscode';

class BaseManage {
    /**
     * 创建终端，并返回对应的属性
     * @param name 终端名
     * @returns 终端属性
     */
    createTerminal(name: string) {
        const terminal = this.getTerminal(name);
        if (terminal) {
            return terminal;
        }

        return vscode.window.createTerminal({ 
            name: name
        });
    }

    /**
     * 获取终端对应的属性
     * @param name 终端名
     * @returns 终端属性
     */
    getTerminal(name: string): vscode.Terminal | null {
        for (const terminal of vscode.window.terminals) {
            if (terminal.name === name) {
                return terminal;
            }
        }
        return null;
    }
}

export {
    BaseManage
};