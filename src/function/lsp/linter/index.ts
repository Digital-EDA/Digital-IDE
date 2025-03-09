import * as vscode from 'vscode';
import { AbsPath, IProgress, LspClient } from '../../../global';

import {
    vlogLinterManager,
    vhdlLinterManager,
    svlogLinterManager,
    reserveLinterManager,
    LinterManager,
    refreshWorkspaceDiagonastics
} from './manager';
import { t } from '../../../i18n';

export async function initialise(
    context: vscode.ExtensionContext,
    hdlFiles: AbsPath[],
    progress: vscode.Progress<IProgress>
) {
    const client = LspClient.DigitalIDE;
    if (!client) {
        vscode.window.showErrorMessage(t('error.common.fail-to-launch-lsp'));
        throw Error('初始化失败');
    }
    
    await refreshWorkspaceDiagonastics(client, hdlFiles, true, progress);
}

export {
    vlogLinterManager,
    vhdlLinterManager,
    svlogLinterManager,
    reserveLinterManager,
    LinterManager
};