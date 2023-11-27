"use strict";
function* walk(path, ext) {
    if (fs.lstatSync(path).isFile()) {
        if (path.endsWith(ext)) {
            yield path;
        }
    }
    else {
        for (const file of fs.readdirSync(path)) {
            const stat = fs.lstatSync(path);
            const filePath = fspath.join(path, file);
            if (stat.isDirectory()) {
                for (const targetPath of walk(filePath, ext)) {
                    yield targetPath;
                }
            }
            else if (stat.isFile()) {
                if (filePath.endsWith(ext)) {
                    yield filePath;
                }
            }
        }
    }
}
async function test(context) {
    if (vscode.workspace.workspaceFolders !== undefined &&
        vscode.workspace.workspaceFolders.length !== 0) {
        const wsPath = hdlPath.toSlash(vscode.workspace.workspaceFolders[0].uri.fsPath);
        for (const file of walk(wsPath, '.v')) {
            if (typeof file === 'string') {
                const fast = await vlogFast(file);
            }
        }
    }
}
//# sourceMappingURL=testMain.js.map