/* eslint-disable @typescript-eslint/naming-convention */
import * as vscode from 'vscode';
import { ChildProcessWithoutNullStreams, spawn } from 'child_process';
import * as fspath from 'path';
import * as fs from 'fs';

import { AbsPath, opeParam } from '../../global';
import { hdlParam } from '../../hdlParser/core';
import { hdlFile, hdlDir, hdlPath } from '../../hdlFs';
import { HardwareOutput, ReportType } from '../../global/outputChannel';
import { HdlFileProjectType } from '../../hdlParser/common';
import { killProcess } from '../../global/util';
import { projectFileManager } from '../projectFile';
import { PLContext } from './xilinx';

/** 安路 Tang Dynasty 6.2 命令行后端。目标器件为 PH1A90SEG325，speed=2。 */
class AnlogicOperation {
    public guiLaunched = false;
    public guiPid = -1;

    // 运行完成回调，由 synth/impl 注册，TD 输出 DIDE_RUN_DONE 时触发，
    // 用于收起 withProgress 进度条
    private runDoneCallback: Partial<Record<'synth' | 'impl', () => void>> = {};

    // 运行前 run.log 的状态基线。TD 在 reset_runs 时清空该日志、直到 run 结束才写回，
    // 若在 wait_run 返回的瞬间读取，会拿到上一次运行遗留的旧日志。
    // 这里记录基线，完成时确认日志确为本次运行所刷新，再触发上层日志分析。
    private runLogGuard: Partial<Record<'synth' | 'impl', { path: AbsPath, mtime: number, size: number }>> = {};

    private get tdBin(): AbsPath {
        return vscode.workspace.getConfiguration('digital-ide.prj.anlogic.install').get<string>('path') || '';
    }

    // 器件速度等级，对应 create_project / import_device 的 -speed 选项
    private get speed(): string {
        return vscode.workspace.getConfiguration('digital-ide.prj.anlogic.install').get<string>('speed') || '2';
    }

    public get prjPath(): AbsPath { return opeParam.prjInfo.arch.prjPath; }
    public get srcPath(): AbsPath { return opeParam.prjInfo.arch.hardware.src; }
    public get datPath(): AbsPath { return opeParam.prjInfo.arch.hardware.data; }

    // 已有 TD 工程目录。留空则在 <arch.prjPath>/anlogic 下新建工程。
    private get configuredPrjDir(): AbsPath {
        return vscode.workspace.getConfiguration('digital-ide.prj.anlogic.project').get<string>('path') || '';
    }

    /**
     * @description 解析 TD 工程所在目录。
     *              配置了 digital-ide.prj.anlogic.project.path 时以该目录为准（支持
     *              绝对路径或相对工作区路径），否则回落到 <arch.prjPath>/anlogic。
     */
    private resolvePrjDir(): AbsPath {
        const configured = this.configuredPrjDir;
        if (!configured) {
            return hdlPath.join(this.prjPath, 'anlogic');
        }
        return fspath.isAbsolute(configured)
            ? hdlPath.toSlash(configured)
            : hdlPath.join(opeParam.workspacePath, configured);
    }

    /**
     * @description 解析 TD 工程名。
     *              优先沿用目标目录中已有的 .al 文件名，避免与 prjName.PL 不一致时
     *              在已有工程旁边又新建一个空工程。目录中只有唯一 .al 时以其为准；
     *              存在多个 .al 时退回 prjName.PL（交由用户显式指定）。
     */
    private resolvePrjName(dir: AbsPath): string {
        const preferred = opeParam.prjInfo.prjName.PL;
        try {
            const als = fs.readdirSync(dir).filter(f => f.toLowerCase().endsWith('.al'));
            if (als.length === 1) {
                return als[0].slice(0, -'.al'.length);
            }
        } catch {
            // 目录不存在或不可读，按默认工程名处理
        }
        return preferred;
    }

    public get prjInfo() {
        const dir = this.resolvePrjDir();
        return {
            path: dir,
            name: this.resolvePrjName(dir),
            device: opeParam.prjInfo.device || 'PH1A90SEG325'
        };
    }

    // TD 文档：device_family 为该器件型号的前 3 位字符（如 PH1A90SEG325 -> ph1），大小写不敏感
    private get family(): string {
        return this.prjInfo.device.slice(0, 3).toLowerCase();
    }

    /**
     * @description 器件 db 文件名，供 import_device 使用。
     *              TD 文档 4.1.1 的检索方法是从现有工程的 run.log 中查找，
     *              此处改为按命名规律推导并在 TD 的 arch 目录下核对：
     *              PH1A90SEG325 -> ph1_90.db。找不到时按前缀回退匹配，
     *              以覆盖 ph1_35p.db 这类带后缀的命名。可通过配置显式覆盖。
     */
    private get deviceDb(): string {
        const configured = vscode.workspace
            .getConfiguration('digital-ide.prj.anlogic.install').get<string>('deviceDb') || '';
        if (configured) {
            return configured;
        }

        const device = this.prjInfo.device;
        const family = this.family;
        // 去掉 family 前缀后，跳过字母再取连续数字：A90SEG325 -> 90
        const matched = device.slice(3).match(/^[A-Za-z]*(\d+)/);
        const num = matched ? matched[1] : '';
        const preferred = num ? `${family}_${num}.db` : `${family}.db`;

        // tdBin 形如 <td>/bin，器件库在其同级 arch 目录下
        if (hdlFile.isDir(this.tdBin)) {
            const archDir = hdlPath.join(fspath.dirname(this.tdBin), 'arch');
            if (hdlFile.isDir(archDir)) {
                if (fs.existsSync(hdlPath.join(archDir, preferred))) {
                    return preferred;
                }
                const prefix = num ? `${family}_${num}` : family;
                const candidates = fs.readdirSync(archDir)
                    .filter(f => f.toLowerCase().startsWith(prefix) && f.toLowerCase().endsWith('.db'));
                if (candidates.length > 0) {
                    return candidates[0];
                }
            }
        }
        return preferred;
    }

    /**
     * @description 扫描工作区中的 .al 工程文件，供用户选择要打开哪一个。
     *              排除 .git / node_modules 等无关目录，避免扫描耗时；
     *              .dideignore 的规则不参与——工程文件本身通常会被忽略，但需要能被列出。
     */
    public scanProjects(): AbsPath[] {
        const skip = new Set(['.git', 'node_modules', '.vscode', 'tmp', 'log', 'doc']);
        const found: AbsPath[] = [];

        const walk = (dir: AbsPath, depth: number) => {
            if (depth > 6) {
                return;
            }
            let entries: string[];
            try {
                entries = fs.readdirSync(dir);
            } catch {
                return;
            }
            for (const name of entries) {
                const full = hdlPath.join(dir, name);
                let isDirectory = false;
                try {
                    isDirectory = fs.statSync(full).isDirectory();
                } catch {
                    continue;
                }
                if (isDirectory) {
                    if (skip.has(name)) {
                        continue;
                    }
                    walk(full, depth + 1);
                } else if (name.toLowerCase().endsWith('.al')) {
                    found.push(full);
                }
            }
        };

        walk(opeParam.workspacePath, 0);
        return found;
    }

    /**
     * @description 弹出工程选择列表，用户选中后写入工作区配置并返回该工程路径。
     *              仅有一个候选时直接返回，不打扰用户。
     */
    public async pickProject(): Promise<AbsPath | undefined> {
        const projects = this.scanProjects();
        if (projects.length === 0) {
            vscode.window.showWarningMessage('安路 TD：工作区内未找到 .al 工程文件');
            return undefined;
        }

        if (projects.length === 1) {
            return projects[0];
        }

        const workspace = opeParam.workspacePath;
        const picked = await vscode.window.showQuickPick(
            projects.map(p => ({
                label: fspath.basename(p),
                description: hdlPath.toSlash(hdlPath.relative(workspace, p)),
                detail: `修改时间 ${new Date(fs.statSync(p).mtimeMs).toLocaleString()}`,
                path: p,
            })),
            {
                title: '选择要打开的安路 TD 工程',
                placeHolder: `工作区内找到 ${projects.length} 个 .al 工程，请选择要打开的一个`,
            }
        );

        return picked?.path;
    }

    /**
     * @description 让用户选择工程并持久化到工作区配置（.vscode/settings.json），
     *              后续 Launch / GUI / Program 都会使用该工程。
     */
    public async selectProject(): Promise<void> {
        const path = await this.pickProject();
        if (!path) {
            return;
        }

        const dir = hdlPath.toSlash(fspath.dirname(path));
        const name = fspath.basename(path);

        // 写入工作区设置，保证与 .al 所在目录一致，无需用户手填
        await vscode.workspace.getConfiguration('digital-ide.prj.anlogic.project')
            .update('path', dir, vscode.ConfigurationTarget.Workspace);

        projectFileManager.invalidate();
        vscode.window.showInformationMessage(`安路 TD：已选定工程 ${name}`);
        HardwareOutput.report(`安路 TD 工程已切换为：${path}`, { level: ReportType.Run });
    }

    public updateAnlogicPath(): string {
        if (hdlFile.isDir(this.tdBin)) {
            const exe = hdlPath.join(hdlPath.toSlash(this.tdBin), 'td_commands_prompt');
            return opeParam.os === 'win32' ? exe + '.exe' : exe;
        }
        return opeParam.os === 'win32' ? 'td_commands_prompt.exe' : 'td_commands_prompt';
    }

    /**
     * @description TD 图形界面可执行文件。与命令行工具同目录，用于打开工程做
     *              位流下载、在线调试等在 Tcl 命令集中缺失的操作。
     */
    private get tdGuiPath(): string {
        if (hdlFile.isDir(this.tdBin)) {
            const exe = hdlPath.join(hdlPath.toSlash(this.tdBin), 'td');
            return opeParam.os === 'win32' ? exe + '.exe' : exe;
        }
        return opeParam.os === 'win32' ? 'td.exe' : 'td';
    }

    private tclPath(path: string): string {
        return `{${hdlPath.toSlash(path).replace(/}/g, '\\}')}}`;
    }

    private send(context: PLContext, command: string) {
        // 回显到输出面板，便于确认实际下发了哪些命令
        HardwareOutput.report(`> ${command}`, { level: ReportType.Run });
        context.process?.stdin.write(command + '\n');
    }

    public async launch(context: PLContext): Promise<string | undefined> {
        // 未配置工程目录时先处理工程归属，避免落到 prj/anlogic 下新建空工程、
        // 或误打开同目录中的其他 .al。工作区只有唯一工程时直接采用，多个则弹列表。
        if (!this.configuredPrjDir) {
            const projects = this.scanProjects();
            if (projects.length === 1) {
                await vscode.workspace.getConfiguration('digital-ide.prj.anlogic.project')
                    .update('path', hdlPath.toSlash(fspath.dirname(projects[0])), vscode.ConfigurationTarget.Workspace);
                projectFileManager.invalidate();
                HardwareOutput.report(`安路 TD：采用工作区内唯一工程 ${projects[0]}`, { level: ReportType.Run });
            } else if (projects.length > 1) {
                await this.selectProject();
                if (!this.configuredPrjDir) {
                    // 用户取消选择，终止本次 Launch
                    return undefined;
                }
            }
        }

        const prjDir = this.prjInfo.path;
        if (this.configuredPrjDir) {
            // 使用已有工程目录：目录必须存在，否则视为配置错误而不是静默新建
            if (!hdlDir.isDir(prjDir)) {
                vscode.window.showErrorMessage(`安路 TD：工程目录不存在 ${prjDir}，请检查 digital-ide.prj.anlogic.project.path`);
                return undefined;
            }
        } else if (!hdlDir.mkdir(prjDir)) {
            vscode.window.showErrorMessage(`mkdir ${prjDir} failed`);
            return undefined;
        }

        const exe = this.updateAnlogicPath();
        // cwd 必须是工程目录：TD 以 cwd 为基准解析工程内的相对路径
        // （.al 中登记的 al_ip/*.xml，以及 export_db 的相对输出路径）。
        // 若设为工作区根目录，IP 会因找不到 XML 而变成 black box，物理实现阶段
        // 报 "Design contains 0 instance" 导致布线失败，最终产出无效位流。
        const process = spawn(exe, [], { shell: true, stdio: 'pipe', cwd: prjDir });

        // TD 命令行冷启动耗时不定，检测到 banner/提示符后再下发命令，最长等 30s 兜底
        let markPromptReady: () => void = () => { };
        const promptReady = new Promise<void>(resolve => { markPromptReady = resolve; });
        let promptDetected = false;

        let outputBuffer = '';
        process.stdout.on('data', data => {
            const text = data.toString();
            outputBuffer += text;
            context.onOutput?.(text);
            HardwareOutput.report(text, { level: ReportType.Info });
            if (!promptDetected && (text.includes('Tang Dynasty') || text.includes('td >'))) {
                promptDetected = true;
                markPromptReady();
            }
            const doneRe = /DIDE_RUN_DONE:(synth|impl)/g;
            let match: RegExpExecArray | null;
            while ((match = doneRe.exec(outputBuffer)) !== null) {
                const run = match[1] === 'impl' ? 'impl' : 'synth';
                // 先确认 run.log 已被本次运行刷新，再触发日志分析
                void this.finishRun(context, run);
            }
            outputBuffer = outputBuffer.replace(/DIDE_RUN_DONE:(synth|impl)/g, '');
        });
        process.stderr.on('data', data => {
            const text = data.toString();
            context.onOutput?.(text);
            HardwareOutput.report(text, { level: ReportType.Error });
        });
        process.on('close', () => {
            context.onProcessExit?.();
            context.process = undefined;
        });

        context.process = process;

        await Promise.race([promptReady, new Promise(resolve => setTimeout(resolve, 30000))]);

        const projectFile = hdlPath.join(prjDir, `${this.prjInfo.name}.al`);
        if (hdlFile.isFile(projectFile)) {
            // 已有工程，沿用现有文件
        } else {
            // 新建工程前先确认顶层已指定，避免建出一个没有 top 的工程
            if (!opeParam.firstSrcTopModule.name) {
                vscode.window.showWarningMessage('安路 TD：未指定设计顶层，工程尚未创建。请在模块树中右键目标模块选择「设置为 src 的顶层文件」后重新 Launch');
                HardwareOutput.show();
                return undefined;
            }
            // 新建工程。语法：create_project <name> <dir> -family <family> -device <device> [-speed <n>]
            // 注意 project_name 必须在 project_directory 之前。
            this.send(context, `create_project ${this.prjInfo.name} ${this.tclPath(prjDir)} -family ${this.family} -device ${this.prjInfo.device} -speed ${this.speed}`);
            await new Promise(resolve => setTimeout(resolve, 3000));
            this.refresh(context);
            await new Promise(resolve => setTimeout(resolve, 3000));
            this.setSrcTop(opeParam.firstSrcTopModule.name, context);
            await new Promise(resolve => setTimeout(resolve, 2000));
            // create_project 以 multi_run 模式打开工程，而分步命令仅 single_run 可用，
            // 因此关闭后按 single run 流程重新打开。
            this.send(context, 'close_project');
            await new Promise(resolve => setTimeout(resolve, 2000));
        }

        // === multi_run 模式（与 TD GUI 的 Build 流程一致）===
        // 1) import_device：加载器件，建立 GlobalDesign 的 chip 上下文。
        //    缺少这一步会导致后续命令报
        //    "Assertion failed: GlobalDesign.chip() != nullptr"（macrolib.cpp）。
        this.send(context, `import_device ${this.deviceDb} -package ${this.prjInfo.device} -speed ${this.speed}`);
        await new Promise(resolve => setTimeout(resolve, 3000));
        // 2) 打开工程（multi_run 模式）。此模式下 synth/impl 通过 launch_runs 驱动，
        //    产物落在 <prj>/<name>_Runs/{syn_1,phy_1,best_result}，
        //    与 TD GUI 完全一致；single_run 模式则把产物写在工程根目录。
        this.send(context, `open_project ${this.tclPath(projectFile)}`);
        await new Promise(resolve => setTimeout(resolve, 3000));

        HardwareOutput.show();
        return undefined;
    }

    // CPU 并行数，传给 launch_runs 的 -jobs
    private get jobs(): string {
        return String(vscode.workspace
            .getConfiguration('digital-ide.prj.anlogic')
            .get<number>('jobs') || 8);
    }

    // 单个 run 的日志文件，位于 <prj>/<name>_Runs/<run>/run.log
    private runLogPath(run: 'syn_1' | 'phy_1'): AbsPath {
        return hdlPath.join(this.prjInfo.path, `${this.prjInfo.name}_Runs`, run, 'run.log');
    }

    // run.log 的 mtime(ms) 与字节数，文件不存在时返回全 0
    private logSnapshot(path: AbsPath): { mtime: number, size: number } {
        try {
            const stat = fs.statSync(path);
            return { mtime: stat.mtimeMs, size: stat.size };
        } catch {
            return { mtime: 0, size: 0 };
        }
    }

    /**
     * @description 等待 run.log 被本次运行刷新。
     *              TD 在 reset_runs 时清空日志、run 全部结束后才写回，
     *              wait_run 返回与文件落盘之间存在毫秒级窗口，此处轮询兜底。
     * @param path run.log 路径
     * @param base 运行前记录的基线状态
     * @returns 日志已刷新返回 true，超时返回 false
     */
    private async waitFreshLog(path: AbsPath, base: { mtime: number, size: number }): Promise<boolean> {
        const deadline = Date.now() + 20000;
        while (Date.now() < deadline) {
            const now = this.logSnapshot(path);
            if (now.size > 0 && (now.mtime > base.mtime || now.size !== base.size)) {
                return true;
            }
            await new Promise(resolve => setTimeout(resolve, 300));
        }
        return false;
    }

    /**
     * @description 运行结束后的收尾：确认 run.log 已刷新再触发上层日志分析。
     *              否则会把上一次运行遗留的 run.log 当成本次结果去分析。
     */
    private async finishRun(context: PLContext, kind: 'synth' | 'impl') {
        const guard = this.runLogGuard[kind];
        this.runLogGuard[kind] = undefined;

        if (guard && !await this.waitFreshLog(guard.path, guard)) {
            HardwareOutput.report(
                `安路 TD：${guard.path} 在本次运行后未更新，run 可能未真正执行，已跳过日志分析`,
                { level: ReportType.Warn }
            );
        } else {
            context.onRunComplete?.(kind);
        }

        // 通知等待中的进度条收起
        this.runDoneCallback?.[kind]?.();
        this.runDoneCallback[kind] = undefined;
    }

    public refresh(context: PLContext) {
        for (const entry of hdlParam.getAllHdlFiles()) {
            if ([HdlFileProjectType.Src, HdlFileProjectType.LocalLib, HdlFileProjectType.RemoteLib].includes(entry.projectType)) {
                this.send(context, `add_files ${this.tclPath(entry.path)}`);
            }
        }
        hdlFile.pickFileRecursive(this.datPath, path => path.endsWith('.adc') || path.endsWith('.sdc'))
            .forEach(path => {
                this.send(context, `add_files ${this.tclPath(path)}`);
            });
    }

    public simulate(context: PLContext) { this.simulateCli(context); }
    public simulateCli(_context: PLContext) {
        vscode.window.showInformationMessage('Anlogic TD：仿真请使用 TD 生成的 ModelSim 脚本');
    }
    public simulateGui(_context: PLContext) { this.simulateCli(_context); }

    public synth(context: PLContext) {
        this.runFlow(context, 'syn_1', 'synth');
    }

    public impl(context: PLContext) {
        this.runFlow(context, 'phy_1', 'impl');
    }

    /**
     * @description 驱动一个 TD run 从复位、启动到等待完成的全过程，并显示进度条。
     *
     *              顺序说明：
     *                reset_runs   —— 必须。run 已有结果时 launch_runs 会报
     *                                PRJ-8805 "need to be reset first"。
     *                                重置 syn_1 会级联重置其下的 phy_1（TD 文档 4.1.17）。
     *                launch_runs  —— 后台启动综合/实现流程。
     *                wait_run     —— 阻塞至该 run 结束，期间 TD 持续输出进度。
     *                puts 标记    —— 供上层识别完成时刻（收起进度条、触发日志分析）。
     *
     *              TD 的 run 进度写在各自 run 目录的 run.log 中，stdout 只有少量提示，
     *              因此这里用不确定进度条 + 输出面板回显来给出反馈。
     */
    private runFlow(context: PLContext, run: 'syn_1' | 'phy_1', kind: 'synth' | 'impl'): void {
        const label = kind === 'synth' ? '综合' : '实现';

        const done = new Promise<void>(resolve => {
            this.runDoneCallback[kind] = resolve;
        });

        void vscode.window.withProgress(
            {
                location: vscode.ProgressLocation.Notification,
                title: `安路 TD：${label}中（${run}）…`,
                cancellable: false,
            },
            async () => {
                // TD 的 run 进度不写入 stdout，这里用不定量进度提示，
                // 具体阶段见输出面板与 <prj>/<name>_Runs/<run>/run.log
                await done;
            }
        );

        HardwareOutput.show();
        HardwareOutput.report(`===== ${label}开始（${run}）=====`, { level: ReportType.Run });

        // 记录本次运行前的 run.log 基线，结束后据此判断日志是否真的被刷新
        const logPath = this.runLogPath(run);
        this.runLogGuard[kind] = { path: logPath, ...this.logSnapshot(logPath) };

        // 1) 复位 run：已有结果时必须先复位，否则 launch_runs 报 PRJ-8805
        this.send(context, `reset_runs ${run}`);
        // 2) 启动并等待
        this.send(context, `launch_runs ${run} -jobs ${this.jobs}`);
        this.send(context, `wait_run ${run}`);
        // 3) 完成标记，供 runDoneCallback 与上层日志分析识别
        this.send(context, `puts "DIDE_RUN_DONE:${kind}"`);
    }

    public build(context: PLContext) {
        this.synth(context);
        this.impl(context);
        this.generateBit(context);
    }

    public generateBit(context: PLContext) {
        // phy_1 的 end_step 已是 bitgen，此处把最佳结果汇集到 best_result 目录，
        // 与 TD GUI 的 save_best_bits 行为一致。
        HardwareOutput.show();
        HardwareOutput.report('===== 汇集位流到 best_result =====', { level: ReportType.Run });
        this.send(context, 'save_best_bits');
        vscode.window.showInformationMessage(
            `安路 TD：位流已汇集到 ${hdlPath.join(this.prjInfo.path, `${this.prjInfo.name}_Runs`, 'best_result')}`
        );
    }

    /**
     * @description 位流下载。TD 的 Tcl 命令集不含烧录命令，下载必须在图形界面的
     *              Download 界面完成，因此这里直接打开 GUI 并提示后续操作。
     */
    public program(_context: PLContext) {
        const prjFile = hdlPath.join(this.prjInfo.path, `${this.prjInfo.name}.al`);

        if (!hdlFile.isFile(prjFile)) {
            vscode.window.showWarningMessage(
                `安路 TD：未找到工程文件 ${prjFile}，无法打开下载界面。 请先执行 Launch 或 BitStream`
            );
            return;
        }

        // 位流位置（multi_run 流程）：
        //   1) <prj>/<name>_Runs/best_result/<name>.bit  —— save_best_bits 汇集
        //   2) <prj>/<name>_Runs/phy_1/<name>.bit        —— phy_1 run 的原始输出
        const candidates = [
            hdlPath.join(this.prjInfo.path, `${this.prjInfo.name}_Runs`, 'best_result', `${this.prjInfo.name}.bit`),
            hdlPath.join(this.prjInfo.path, `${this.prjInfo.name}_Runs`, 'phy_1', `${this.prjInfo.name}.bit`),
        ];
        const bit = candidates.find(p => hdlFile.isFile(p));

        // 位流存在时在提示中给出路径，方便在 Download 界面直接选取
        if (bit) {
            vscode.window.showInformationMessage(
                `安路 TD：Tcl 不支持烧录，已打开图形界面。请在 Download 界面选择位流：${bit}`,
                '打开 GUI'
            ).then(pick => {
                if (pick === '打开 GUI') {
                    this.openGui(prjFile);
                }
            });
        } else {
            // 位流尚未生成时直接打开 GUI，用户可在其中先跑流程再下载
            this.openGui(prjFile);
        }
    }

    /**
     * @description 打开 TD 图形界面并载入当前工程。
     *              TD 的 Tcl 命令集（SWUG105）中没有打开 GUI 的命令，因此这里直接
     *              以独立进程方式启动 td.exe，并把 .al 文件作为参数传入——这与
     *              Windows 中双击 .al 文件打开工程的命令完全一致。
     */
    public async gui(_context: PLContext) {
        const prjFile = hdlPath.join(this.prjInfo.path, `${this.prjInfo.name}.al`);
        if (!hdlFile.isFile(prjFile)) {
            vscode.window.showWarningMessage(
                `安路 TD：未找到工程文件 ${prjFile}。请先执行 Launch 创建或指定已有工程后再打开 GUI`
            );
            return;
        }
        this.openGui(prjFile);
    }

    /**
     * @description 启动 td.exe 打开指定工程。用 detached + unref 让 GUI 独立于
     *              扩展宿主进程，关闭 VS Code 不会连带关掉 TD。
     */
    private openGui(prjFile: AbsPath): void {
        try {
            // 注意：这里传的是普通路径，不能用 tclPath——花括号是 TCL 语法，
            // 作为进程参数传给 td.exe 会被当成路径的一部分。
            const child = spawn(this.tdGuiPath, [hdlPath.toSlash(prjFile)], {
                detached: true,
                stdio: 'ignore',
                // 与命令行一致，以工程目录为 cwd，保证工程内相对路径可解析
                cwd: fspath.dirname(prjFile),
            });
            child.unref();

            this.guiPid = child.pid ?? -1;
            this.guiLaunched = true;

            HardwareOutput.report(`已启动 TD 图形界面：${prjFile}`, { level: ReportType.Info });
            HardwareOutput.show();
            vscode.window.showInformationMessage('安路 TD：图形界面已启动，可在其中进行位流下载与在线调试');
        } catch (error) {
            vscode.window.showErrorMessage(`安路 TD：启动图形界面失败 ${error}`);
        }
    }
    // TD 文档定义的 Exit 为"关闭工程"，因此同时关闭图形界面
    public async exit(context: PLContext) {
        this.send(context, 'exit');
        await this.closeAllWindows();
    }
    public async closeAllWindows() {
        if (this.guiPid > 0) {
            await killProcess(this.guiPid);
            this.guiPid = -1;
            this.guiLaunched = false;
        }
    }
    // TD 使用 top_module 命令设置设计顶层，而非 Vivado 的 set_property top
    public setSrcTop(name: string, context: PLContext) {
        // 顶层未设置时 firstSrcTopModule.name 为空串，直接下发会产生 "top_module " 空参数
        if (!name) {
            vscode.window.showWarningMessage('安路 TD：未指定设计顶层，请在模块树中右键目标模块选择「设置为 src 的顶层文件」后重新 Launch');
            return;
        }
        this.send(context, `top_module ${name}`);
    }
    public setSimTop(name: string, context: PLContext) { this.setSrcTop(name, context); }
    public addFiles(files: string[], context: PLContext) { files.forEach(file => this.send(context, `add_files ${this.tclPath(file)}`)); }
    public delFiles(_files: string[], _context: PLContext) { vscode.window.showInformationMessage('安路 TD：请在工程中移除文件后重新 Launch'); }
    // 返回对应 run 的 run.log，供上层做综合/实现结果分析。
    // multi_run 流程下日志位于 <prj>/<name>_Runs/<run>/run.log。
    public getRunLogPath(run: 'synth' | 'impl'): AbsPath | undefined {
        const log = this.runLogPath(run === 'synth' ? 'syn_1' : 'phy_1');
        return hdlFile.isFile(log) ? log : undefined;
    }
}

export { AnlogicOperation };
