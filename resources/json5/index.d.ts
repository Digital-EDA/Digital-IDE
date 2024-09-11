// It seems that webpack cannot package the json5 correctly

declare module JSON5 {
    export function parse(text: string): any;
} 

export = JSON5;