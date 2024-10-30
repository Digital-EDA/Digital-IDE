/* eslint-disable @typescript-eslint/naming-convention */

import { opeParam } from "../../global";
import { ThemeType } from "../../global/enum";
import { hdlFile, hdlPath } from "../../hdlFs";
import { HdlModuleParam, HdlModulePort, HdlModulePortType } from "../../hdlParser/common";
import { getThemeColorKind } from "./common";


const lightArrowSvgCache: Record<string, string> = {
    'left': '',
    'right': '',
    'left-right': '',
    'left-dot': '',
    'right-dot': ''
};

const darkArrowSvgCache: Record<string, string> = {
    'left': '',
    'right': '',
    'left-right': '',
    'left-dot': '',
    'right-dot': ''
};


function getArrowSvgString(name: 'left' | 'right' | 'left-right' | 'left-dot' | 'right-dot'): string {
    const themeType = getThemeColorKind();
    const arrowSvgCache = (themeType === ThemeType.Light) ? lightArrowSvgCache: darkArrowSvgCache;
    
    let svgString = arrowSvgCache[name];
    if (svgString.length === 0) {
        const iconFile = name + '-arrow.svg';
        const svgDir = hdlPath.join(opeParam.extensionPath, 'images', 'svg');
        const svgPath = hdlPath.join(svgDir, themeType, iconFile);
        const readSvgString = hdlFile.readFile(svgPath);
        if (readSvgString) {
            svgString = readSvgString;
            arrowSvgCache[name] = readSvgString;
        }
    }
    return svgString;
}

function makeDiagram(params: HdlModuleParam[], ports: HdlModulePort[]): string {
    // make params block
    const diagramParamWrapper = makeDiagramParamWrapper(params);
    
    // make ports block
    const diagramPortWrapper = makeDiagramPortWrapper(ports);

    const diagram = `<div class="diagram-container"><div class="diagram">${diagramParamWrapper}${diagramPortWrapper}</div></div>`;
    return diagram;
}


function makeDiagramParamWrapper(params: HdlModuleParam[]): string {
    if (params.length === 0) {
        return '';
    }
    let diagramParams = '';
    for (const param of params) {
        let diagramParam = '<div>' + param.name;
        if (param.init && param.init.length > 0) {
            diagramParam += `(${param.init})`;
        }
        diagramParam += '</div>';
        diagramParams += diagramParam;
    }
    const diagramParamWrapper =  `<div class="diagram-ports-wrapper"><div style="width: 55px;"></div><div class="diagram-params"><div></div><div align="left">${diagramParams}</div></div></div>`;
    return diagramParamWrapper;
}


function makeDiagramPortWrapper(ports: HdlModulePort[]): string {
    if (ports.length === 0) {
        return '';
    }

    const leftPorts = ports.filter(port => port.type === HdlModulePortType.Input || port.type === HdlModulePortType.Inout);
    const rightPorts = ports.filter(port => port.type === HdlModulePortType.Output);

    const leftDirection = makeLeftDirection(leftPorts);    
    const diagramPorts = makeDiagramPorts(leftPorts, rightPorts);    
    const rightDirection = makeRightDirection(rightPorts);
    
    const diagramPortWrapper = `<div class="diagram-ports-wrapper">${leftDirection}${diagramPorts}${rightDirection}</div>`;
    return diagramPortWrapper;
}

function isValidWidth(portWidth: string | undefined): boolean {
    if (portWidth === undefined || portWidth === '' || portWidth === '1') {
        return false;
    }
    return true;
}

function makePortCaption(port: HdlModulePort, direction: 'left' | 'right'): string {
    if (!isValidWidth(port.width)) {
        return '';
    }
    return `<div class="port-width-${direction}-caption">${port.width}</div>`;
}

function makePortArrow(port: HdlModulePort, direction: 'left' | 'right'): string {
    if (port.type === HdlModulePortType.Inout) {
        return getArrowSvgString('left-right');
    }
    if (direction === 'left') {
        if (port.type === HdlModulePortType.Input) {
            if (isValidWidth(port.width)) {
                return getArrowSvgString('right-dot');
            } else {
                return getArrowSvgString('right');
            }
        } else if (port.type === HdlModulePortType.Output) {
            if (isValidWidth(port.width)) {
                return getArrowSvgString('left-dot');
            } else {
                return getArrowSvgString('left');
            }
        }
    } else if (direction === 'right') {
        if (port.type === HdlModulePortType.Input) {
            if (isValidWidth(port.width)) {
                return getArrowSvgString('left-dot');
            } else {
                return getArrowSvgString('left');
            }
        } else if (port.type === HdlModulePortType.Output) {
            if (isValidWidth(port.width)) {
                return getArrowSvgString('right-dot');
            } else {
                return getArrowSvgString('right');
            }
        }
    }
    return '';
}

function makeLeftDirection(leftPorts: HdlModulePort[]): string {
    let leftDirection = '';
    for (const port of leftPorts) {
        const portCaption = makePortCaption(port, 'left');
        const portArrow = makePortArrow(port, 'left');
        const arrow = `<div class="arrow-wrapper">${portCaption}${portArrow}</div>`;
        leftDirection += arrow;
    }
    return `<div class="left-direction">${leftDirection}</div>`;
}

function makePortName(port: HdlModulePort): string {
    let portClass = '';
    if (port.type === HdlModulePortType.Input) {
        portClass = 'i-port-name';
    } else if (port.type === HdlModulePortType.Output) {
        portClass = 'o-port-name';
    } else {
        portClass = 'io-port-name';
    }
    return `<div class="${portClass}">${port.name}</div>`;
}

function makeDiagramPorts(leftPorts: HdlModulePort[], rightPorts: HdlModulePort[]): string {
    let leftIndex = 0;
    let rightIndex = 0;
    let diagramePorts = '';
    while (leftIndex < leftPorts.length && rightIndex < rightPorts.length) {
        const leftPortName = makePortName(leftPorts[leftIndex ++]);
        const rightPortName = makePortName(rightPorts[rightIndex ++]);      
        const diagramPortItem = `<div class="digrame-port-item">${leftPortName}${rightPortName}</div>`;
        diagramePorts += diagramPortItem;
    }
    while (leftIndex < leftPorts.length) {
        const leftPortName = makePortName(leftPorts[leftIndex ++]);
        const diagramPortItem = `<div class="digrame-port-item">${leftPortName}<div></div></div>`;
        diagramePorts += diagramPortItem;
    }
    while (rightIndex < rightPorts.length) {
        const rightPortName = makePortName(rightPorts[rightIndex ++]);        
        const diagramPortItem = `<div class="digrame-port-item"><div></div>${rightPortName}</div>`;
        diagramePorts += diagramPortItem;
    }
    return `<div class="diagram-ports">${diagramePorts}</div>`;
}

function makeRightDirection(rightPorts: HdlModulePort[]): string {
    let rightDirection = '';    
    for (const port of rightPorts) {
        const portCaption = makePortCaption(port, 'right');
        let portArrow = makePortArrow(port, 'right');
        portArrow = portArrow.replace('-0.5 -0.5 125 45', '20 -0.5 125 45');
        
        const arrow = `<div class="arrow-wrapper">${portCaption}${portArrow}</div>`;
        rightDirection += arrow;
    }

    return `<div class="right-direction">${rightDirection}</div>`;
}

export {
    makeDiagram
};