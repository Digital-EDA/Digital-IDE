interface SynthOptions {
    path: string
    type: string
    argu: string
}

interface ExportOptions {
    path?: string
    type?: string
    argu?: string
}

declare module Netlist {
    export class NetlistKernel {
        public async launch();
        public exec(command: string);
        public printHelp(): string;
        public setInnerOutput(params: boolean);
        public setMessageCallback(callback: (message: string, type: string) => void);
        public load(files: string[]): string;
        public synth(options: SynthOptions);
        public export(options: ExportOptions): string;
        public reset();
        public exit();
    }
}

export = Netlist;