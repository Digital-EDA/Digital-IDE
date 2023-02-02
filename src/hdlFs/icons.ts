import { opeParam, AbsPath, Enum } from '../global';
import * as hdlPath from './path';

interface IconConfig {
    light: AbsPath
    dark: AbsPath
};

function getIconPath(themeType: Enum.ThemeType, iconName: string): AbsPath {
    const iconFile = iconName + '.svg';
    const svgDir = hdlPath.join(opeParam.extensionPath, 'images', 'svg');
    const iconPath = hdlPath.join(svgDir, themeType, iconFile);
    return iconPath;
}

function getIconConfig(iconName: string): IconConfig {
    return {
        light: getIconPath(Enum.ThemeType.Light, iconName),
        dark: getIconPath(Enum.ThemeType.Dark, iconName)
    };
}

module.exports = {
    getIconPath,
    getIconConfig
};