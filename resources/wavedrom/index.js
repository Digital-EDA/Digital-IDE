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

/**
 * 
 * @param {number} id 
 * @param {any} json 
 * @param {any} style 'dark' or 'light'
 * @returns {string}
 */
function renderWaveDrom(id, json, style) {
    const skin = selectSkin(style);
    const renderObj = renderAny(id, json, skin);
    const svgString = onmlStringify(renderObj);
    return svgString;
}

const Wavedrom = {
    renderWaveDrom
};

module.exports = Wavedrom;