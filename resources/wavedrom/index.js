/* eslint-disable @typescript-eslint/naming-convention */
const renderAny = require('wavedrom/lib/render-any');
const onmlStringify = require('onml/stringify.js');
const darkSkin = require('wavedrom/skins/dark');
const lightSkin = require('wavedrom/skins/default');

function selectSkin(skin) {
    if (skin === 'dark') {
        return darkSkin;
    } else if (skin === 'light') {
        return lightSkin;
    }
    return darkSkin;
}

function replaceRectsWithCustomString(svgString, style) {
    const regex = /<rect\s+([^>]*)\s*\/?>/gs;
        
    const replacedSvgString = svgString.replace(regex, (match, attributes, content) => {
        match = match.replace('fill:#FFF;', 'fill:var(--vscode-editor-background)');        
        return match;
    });
    
    return replacedSvgString;
}

/**
 * 
 * @param {number} id 
 * @param {any} json 
 * @param {'dark' | 'light'} style
 * @returns {string}
 */
function renderWaveDrom(id, json, style) {
    const skin = selectSkin(style);
    const renderObj = renderAny(id, json, skin);
    let svgString = onmlStringify(renderObj);
    
    // TODO: more elegant ? 这里是为了解决黑色模式下部分 rect 仍然是白色背景
    svgString = replaceRectsWithCustomString(svgString, style);

    return svgString;
}

const Wavedrom = {
    renderWaveDrom
};

module.exports = Wavedrom;