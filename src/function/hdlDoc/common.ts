/* eslint-disable @typescript-eslint/naming-convention */
import * as assert from 'assert';
import * as vscode from 'vscode';
import * as fs from 'fs';
import * as readline from 'readline';

import * as JSON5 from '../../../resources/json5';
import * as Wavedrom from '../../../resources/wavedrom';
import * as showdown from 'showdown';

import { ThemeType } from '../../global/enum';
import { MainOutput, ReportType } from '../../global';
import { HdlModuleParam, HdlModulePort } from '../../hdlParser/common';

const Count = {
    svgMakeTimes: 0
};

const converter = new showdown.Converter({
    tables : true,
    literalMidWordUnderscores : true,
    strikethrough : true,
    simpleLineBreaks : true
});

enum MarkdownTag {
    Title = '#',
    Quote = '>',
    Bold = '**',
    Italic = '*',
    InlineCode = '`',
    UnorderedList = '-'
};

enum MarkdownAlign { Left, Center, Right };
enum RenderType { Wavedrom, Markdown, Diagram };

function getAlignSpliter(align: MarkdownAlign): string {
    switch (align) {
        case MarkdownAlign.Left: return ':---';
        case MarkdownAlign.Center: return ':---:';
        case MarkdownAlign.Right: return '---:';
        default: return '';
    }
}

function joinString(...strings: string[]): string {
    return strings.join(' ');
}

function catString(...strings: string[]): string {
    return strings.join('');
}

function getThemeColorKind(): ThemeType {
    const currentColorKind = vscode.window.activeColorTheme.kind;
    if (currentColorKind === vscode.ColorThemeKind.Dark || 
        currentColorKind === vscode.ColorThemeKind.HighContrast) {
        return ThemeType.Dark;
    } else {
        return ThemeType.Light;
    }
}

abstract class BaseDoc {
    value: string;
    constructor(value: string) {
        this.value = value;
    }
};


class Text extends BaseDoc {
    constructor(value: string) {
        super(value);
    }
};

class Title extends BaseDoc {
    level: number;
    constructor(value: string, level: number) {
        super(value);
        this.level = level;
        const prefix = MarkdownTag.Title.repeat(level);
        this.value = joinString(prefix, value);
    }
};


class UnorderedList {
    value: string;
    constructor(values: string[]) {
        this.value = '';
        for (const v of values) {
            this.value += joinString(MarkdownTag.UnorderedList, v, '\n');
        }
    }
};

class OrderedList {
    value: string = '';
    constructor(values: string[]) {
        values.forEach((v, i) => {
            const id = i + 1;
            this.value += joinString(id + '.', v, '\n');
        });
    }
};

class Quote extends BaseDoc {
    /**
     * @description quote, tag > in markdown
     * @param {string} value 
     */
    constructor(value: string) {
        super(value);
        this.value = joinString(MarkdownTag.Quote, value);   
    }
};

class Bold extends BaseDoc {
    constructor(value: string) {
        super(value);
        this.value = catString(MarkdownTag.Bold, value, MarkdownTag.Bold);
    }
};

class Italic extends BaseDoc {
    constructor(value: string) {
        super(value);
        this.value = catString(MarkdownTag.Italic, value, MarkdownTag.Italic);
    }
};

class InlineCode extends BaseDoc {
    constructor(value: string) {
        super(value);
        this.value = catString(MarkdownTag.InlineCode, value, MarkdownTag.InlineCode);
    }
}

class Split extends BaseDoc {
    constructor() {
        super('---');
    }
};

class Table extends BaseDoc {

    constructor(fieldNames: string[], rows: string[][], align: MarkdownAlign = MarkdownAlign.Left) {
        const colNum = fieldNames.length;
        const rowNum = rows.length;
        const alignString = getAlignSpliter(align);

        let value = catString('| ', fieldNames.join(' | '), ' |', '\n');
        const alignUnit = catString('| ', alignString, ' ');
        value += catString(alignUnit.repeat(colNum), '|', '\n');
        for (let row = 0; row < rowNum; ++ row) {
            const data = rows[row];
            value += catString('| ', data.join(' | '), '|');
            if (row < rowNum - 1) {
                value += '\n';
            }
        }
        super(value);
    }
};

abstract class RenderString {
    line: number;
    type: RenderType;

    constructor(line: number, type: RenderType) {
        this.line = line;
        this.type = type;
    }

    abstract render(): string;
}

interface MarkdownStringValue {
    tag: BaseDoc
    end: string
};

class MarkdownString extends RenderString {
    values: MarkdownStringValue[];
    constructor(line: number) {
        super(line, RenderType.Markdown);
        this.values = [];
    }
    addText(value: string, end: string='\n') {
        const tag = new Text(value);
        this.values.push({tag, end});
    }
    addTitle(value: string, level: number, end: string='\n') {
        const tag = new Title(value, level);
        this.values.push({tag, end});
    }
    addQuote(value: string, end: string='\n') {
        const tag = new Quote(value);
        this.values.push({tag, end});
    }
    addBold(value: string, end: string='\n') {
        const tag = new Bold(value);
        this.values.push({tag, end});
    }
    addEnter() {
        const tag = {value : ''};
        const end = '\n';
        this.values.push({tag, end});
    }
    addItalic(value: string, end='\n') {
        const tag = new Italic(value);
        this.values.push({tag, end});
    }
    addInlineCode(value: string, end='\n') {
        const tag = new InlineCode(value);
        this.values.push({tag, end});
    }
    addUnorderedList(values: string[]) {
        const end = '';
        const tag = new UnorderedList(values);
        this.values.push({tag, end});
    }
    addOrderedList(values: string[]) {
        const end = '';
        const tag = new OrderedList(values);
        this.values.push({tag, end});
    }
    addSplit(value: string) {
        const end = '\n';
        const tag = new Split();
        this.values.push({tag, end});
    }
    addTable(fieldNames: string[], rows: string[][], align=MarkdownAlign.Left, end='\n') {
        const tag = new Table(fieldNames, rows, align);
        this.values.push({tag, end});
    }
    renderMarkdown() {
        let markdown = '';
        for (const md of this.values) {
            markdown += md.tag.value + md.end;
        }
        return markdown;
    }
    render() {
        const rawMD = this.renderMarkdown();
        return converter.makeHtml(rawMD);
    }
};

class WavedromString extends RenderString {
    value: string;
    desc: string;

    constructor(line: number, desc: string) {
        super(line, RenderType.Wavedrom);
        this.value = '';
        this.desc = desc;
    }
    add(text: string) {
        this.value += text;
    }
    render(): string {
        const style = getThemeColorKind();
        return makeWaveDromSVG(this.value, style);
    }
};

class DiagramString extends RenderString {
    params: HdlModuleParam[];
    ports: HdlModulePort[];

    constructor(line: number) {
        super(line, RenderType.Diagram);
        this.params = [];
        this.ports = [];
    }

    add() {

    }

    render(): string {

        return '';
    }
}

function parseJson5(text: string): any {
    let json = null;
    try {
        json = JSON5.parse(text);
    } catch (error) {
        MainOutput.report('error happen when parse json ', ReportType.Error);
        MainOutput.report(error, ReportType.Error);
    }
    return json;
}


function makeWaveDromSVG(wavedromComment: string, style: ThemeType): string {
    const json = parseJson5(wavedromComment);
    try {
        if (!json) {
            return '';
        }
        const svgString = Wavedrom.renderWaveDrom(Count.svgMakeTimes, json, style);
        Count.svgMakeTimes += 1;
        return svgString;
    } catch (error) {
        MainOutput.report('error happen when render ' + wavedromComment, ReportType.Error);
        MainOutput.report(error, ReportType.Error);
        return '';
    }
}

/**
 * extract wavedrom comment from hdl file
 * @param path 
 * @returns 
 */
async function getWavedromsFromFile(path: string): Promise<WavedromString[] | undefined> {
    let lineID = 0;
    let findWavedrom = false;
    const wavedroms: WavedromString[] = [];

    const fileStream = fs.createReadStream(path, 'utf-8');
    const rl = readline.createInterface({
      input: fileStream,
      crlfDelay: Infinity
    });

    for await (const line of rl) {
        lineID += 1;
        if (findWavedrom) {
            if (/\*\//g.test(line)) {
                findWavedrom = false;
            } else {
                const currentWav = wavedroms[wavedroms.length - 1];
                currentWav.add(line.trim());
            }
        } else {
            if (/\/\*[\s\S]*(@wavedrom)/g.test(line)) {
                findWavedrom = true;
                let spliters = line.trim().split('@wavedrom');
                let desc = spliters[spliters.length - 1];
                const newWavedrom = new WavedromString(lineID, desc);
                wavedroms.push(newWavedrom);
            }
        }
    }

    return wavedroms;
}

function mergeSortByLine(docs: MarkdownString[], svgs: WavedromString[]): RenderString[] {
    const renderList = [];
    let i = 0, j = 0;
    while (i < docs.length && j < svgs.length) {
        if (docs[i].line < svgs[j].line) {
            renderList.push(docs[i]);
            i ++;
        } else {
            renderList.push(svgs[j]);
            j ++;
        }
    }
    while (i < docs.length) {
        renderList.push(docs[i]);
        i ++;
    }
    while (j < svgs.length) {
        renderList.push(svgs[j]);
        j ++;
    }
    return renderList;
}


export {
    converter,
    mergeSortByLine,
    RenderType,
    BaseDoc,
    MarkdownString,
    WavedromString,
    RenderString,
    makeWaveDromSVG,
    getWavedromsFromFile,
    getThemeColorKind,
    Count
};