import * as vscode from 'vscode';
import { opeParam, AbsPath, Enum } from '../global';
import * as hdlPath from './path';

interface IconConfig {
    readonly light: vscode.Uri
    readonly dark: vscode.Uri
};

function getIconPath(themeType: Enum.ThemeType, iconName: string): vscode.Uri {
    const iconFile = iconName + '.svg';
    const svgDir = hdlPath.join(opeParam.extensionPath, 'images', 'svg');
    const iconPath = hdlPath.join(svgDir, themeType, iconFile);
    return vscode.Uri.file(iconPath);
}

function getIconConfig(iconName: string): IconConfig {
    return {
        light: getIconPath(Enum.ThemeType.Light, iconName),
        dark: getIconPath(Enum.ThemeType.Dark, iconName)
    };
}

export {
    getIconPath,
    getIconConfig
};