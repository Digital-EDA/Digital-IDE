import * as vscode from 'vscode';
import * as fspath from 'path';
import * as fs from 'fs';

import { AbsPath, opeParam } from '../global';
import { hdlPath } from '../hdlFs';
import { MainOutput, ReportType } from '../global/outputChannel';

/**
 * @description 工程文件中的单个文件条目。
 *              disabled 对应 Vivado 的 AutoDisabled 或 TD 的 AutoExcluded，
 *              表示该文件虽然登记在工程中但不参与编译。
 */
export interface PrjFileEntry {
    path: AbsPath;
    disabled: boolean;
}

/**
 * @description 工程文件的解析结果。字段全部可选，解析失败的项留空即可，
 *              调用方按"有则用、无则回退"的方式消费，避免解析异常影响启动。
 */
export interface PrjFileInfo {
    // 工程文件类型（al = 安路 TD，xpr = Xilinx Vivado）
    kind: 'al' | 'xpr';
    // 工程文件本身及其所在目录（作为相对路径的基准）
    file: AbsPath;
    dir: AbsPath;
    // 设计顶层 / 仿真顶层，取自工程文件中的登记值
    topModuleSrc?: string;
    topModuleSim?: string;
    // 器件信息，用于与 property.json 比对
    device?: string;
    family?: string;
    speed?: string;
    // 按用途分类的文件列表
    srcFiles: PrjFileEntry[];
    simFiles: PrjFileEntry[];
    dataFiles: PrjFileEntry[];
    // IP 定义文件（.al 的 IP_FILE，.xpr 的 BlockSrcs）。这些不是 HDL，
    // 但属于工程内容，单独归类以便与设计源区分。
    ipFiles: PrjFileEntry[];
}

// ============================================================================
// 小工具
// ============================================================================

/**
 * @description 取指定标签的第一个文本内容，如 <MODULE>pxf100_top</MODULE> -> pxf100_top
 */
function firstTagText(xml: string, tag: string): string | undefined {
    const m = xml.match(new RegExp(`<${tag}>([\\s\\S]*?)</${tag}>`));
    return m ? m[1].trim() : undefined;
}

/**
 * @description 取指定标签块的全部内容（含标签本身），用于逐段处理 FileSet 之类
 */
function tagBlocks(xml: string, tag: string): string[] {
    return xml.match(new RegExp(`<${tag}\\b[^>]*>[\\s\\S]*?</${tag}>`, 'g')) || [];
}

/**
 * @description 取单个元素的属性值
 */
function attrOf(element: string, name: string): string | undefined {
    const m = element.match(new RegExp(`\\b${name}="([^"]*)"`));
    return m ? m[1] : undefined;
}

/**
 * @description 解析 XML 实体，工程文件中路径可能含 &amp; 等转义
 */
function unescapeXml(s: string): string {
    return s
        .replace(/&lt;/g, '<')
        .replace(/&gt;/g, '>')
        .replace(/&quot;/g, '"')
        .replace(/&apos;/g, "'")
        .replace(/&amp;/g, '&');
}

/**
 * @description 收集一段 XML 中所有 <File .../> 或 <File ...>...</File> 的路径与禁用标记
 */
function collectFiles(block: string): PrjFileEntry[] {
    const result: PrjFileEntry[] = [];
    // 匹配整个 File 元素（自闭合或成对），以便读取其 FileInfo 中的 Attr
    const fileBlocks = block.match(/<File\b[^>]*\/>|<File\b[^>]*>[\s\S]*?<\/File>/g) || [];
    for (const fb of fileBlocks) {
        const raw = attrOf(fb, 'Path');
        if (!raw) {
            continue;
        }
        // Vivado: AutoDisabled；TD: AutoExcluded
        const disabled = /Name="(AutoDisabled|AutoExcluded)"\s+Val="(1|true)"/i.test(fb);
        result.push({ path: unescapeXml(raw), disabled });
    }
    return result;
}

// ============================================================================
// 安路 TD .al 解析
// ============================================================================

/**
 * @description 工程文件的最小有效性校验。
 *
 *              解析器基于正则而非完整 XML 解析（工程文件由厂商工具生成，
 *              结构稳定且体积在建控范围内）。正则的代价是截断的文件不会报错，
 *              只会解析出空结果，于是树里会出现一个内容为空的工程节点。
 *              这里用闭合标签做一个廉价的完整性判断，把截断文件挡在外面。
 */
function isWellFormed(content: string): boolean {
    return /<\/Project\s*>/.test(content);
}

/**
 * @description 解析 .al（XML）。结构要点：
 *              <Source_Files> 下按语言/用途分为多个子块：
 *                <Verilog> / <VHDL>   设计源文件
 *                <IP_FILE>            IP 定义（al_ip/*.xml、*.ipc）
 *                <ADC_FILE> / <SDC_FILE>  管脚与时序约束
 *              这些子块必须分别收集：Source_Files 整块收集会把 IP 与约束
 *              一并算作设计源，导致约束在树里重复出现、统计数虚高。
 *              <TOP_MODULE><MODULE> 为设计顶层，路径均相对 .al 所在目录。
 */
function parseAl(content: string, file: AbsPath, dir: AbsPath): PrjFileInfo {
    const info: PrjFileInfo = {
        kind: 'al', file, dir,
        srcFiles: [], simFiles: [], dataFiles: [], ipFiles: [],
    };

    // 设计顶层：优先 MODULE，退回 LABEL
    const topBlock = firstTagText(content, 'TOP_MODULE');
    if (topBlock) {
        info.topModuleSrc = firstTagText(topBlock, 'MODULE') || firstTagText(topBlock, 'LABEL');
    }

    // 器件信息
    const hwBlock = firstTagText(content, 'HardWare');
    if (hwBlock) {
        info.family = firstTagText(hwBlock, 'Family');
        info.device = firstTagText(hwBlock, 'Device');
        // .al 中的 Speed 形如 "-2"，去掉前导负号便于与 property.json 的 "2" 比对
        const speed = firstTagText(hwBlock, 'Speed');
        info.speed = speed ? speed.replace(/^-/, '') : undefined;
    }

    const srcBlock = firstTagText(content, 'Source_Files');
    if (srcBlock) {
        // 设计源：仅取 HDL 语言子块
        for (const tag of ['Verilog', 'VHDL', 'SystemVerilog']) {
            for (const sub of tagBlocks(srcBlock, tag)) {
                info.srcFiles.push(...collectFiles(sub));
            }
        }

        // IP 定义文件
        for (const sub of tagBlocks(srcBlock, 'IP_FILE')) {
            info.ipFiles.push(...collectFiles(sub));
        }

        // 约束文件（ADC 为管脚约束，SDC 为时序约束）
        for (const tag of ['ADC_FILE', 'SDC_FILE']) {
            for (const sub of tagBlocks(srcBlock, tag)) {
                info.dataFiles.push(...collectFiles(sub));
            }
        }
    }

    return info;
}

// ============================================================================
// Xilinx Vivado .xpr 解析
// ============================================================================

// FileSet 类型到用途的映射。Utils 是厂商工具生成的辅助脚本，解析无意义，
// 因此跳过；BlockSrcs 为 IP 与 Block Design 的生成物，归入 ipFiles。
const XPR_FILESET_KIND: Record<string, 'src' | 'sim' | 'data' | 'ip' | 'skip'> = {
    DesignSrcs: 'src',
    SimulationSrcs: 'sim',
    Constrs: 'data',
    BlockSrcs: 'ip',
    Utils: 'skip',
};

/**
 * @description 解析 .xpr（XML）。结构要点：
 *              <FileSet Name="sources_1" Type="DesignSrcs"> 内既有 <File Path="...">
 *              也有 <Config><Option Name="TopModule" Val="..."/>
 *              Type 决定用途（DesignSrcs/SimulationSrcs/Constrs）。
 *              路径以 $PPRDIR 开头，$PPRDIR 即 .xpr 所在目录。
 */
function parseXpr(content: string, file: AbsPath, dir: AbsPath): PrjFileInfo {
    const info: PrjFileInfo = {
        kind: 'xpr', file, dir,
        srcFiles: [], simFiles: [], dataFiles: [], ipFiles: [],
    };

    for (const fsBlock of tagBlocks(content, 'FileSet')) {
        const type = attrOf(fsBlock, 'Type') || '';
        const kind = XPR_FILESET_KIND[type];
        if (!kind || kind === 'skip') {
            continue;
        }

        const files = collectFiles(fsBlock);
        // 顶层登记在 FileSet 内的 <Config><Option Name="TopModule" Val="..."/>
        const cfgBlock = firstTagText(fsBlock, 'Config');
        const topModule = cfgBlock
            ? attrOf(cfgBlock.match(/<Option\b[^>]*Name="TopModule"[^>]*\/?>/)?.[0] || '', 'Val')
            : undefined;

        if (kind === 'src') {
            info.srcFiles.push(...files);
            if (topModule) {
                info.topModuleSrc = topModule;
            }
        } else if (kind === 'sim') {
            info.simFiles.push(...files);
            if (topModule) {
                info.topModuleSim = topModule;
            }
        } else if (kind === 'ip') {
            info.ipFiles.push(...files);
        } else {
            info.dataFiles.push(...files);
        }
    }

    return info;
}

// ============================================================================
// 对外接口
// ============================================================================

/**
 * @description 把工程文件中的相对路径（含 Vivado 的 $PPRDIR 变量）解析为绝对路径。
 */
function resolvePath(raw: string, dir: AbsPath): AbsPath | undefined {
    // Vivado 用 $PPRDIR 表示工程文件所在目录
    let p = raw.replace(/^\$PPRDIR/, dir.replace(/\\/g, '/'));
    // $PSRCDIR / $PGENDIR 等其余变量本项目暂不涉及，遇到则跳过，避免产生错误路径
    if (/\$[A-Z]+DIR/.test(p)) {
        return undefined;
    }
    if (!fspath.isAbsolute(p)) {
        p = fspath.join(dir, p);
    }
    return hdlPath.toSlash(fspath.normalize(p));
}

/**
 * @description 把解析结果中的相对路径全部转成绝对路径，并过滤掉不存在或已被禁用的文件。
 */
function normalize(info: PrjFileInfo): PrjFileInfo {
    const conv = (entries: PrjFileEntry[]): PrjFileEntry[] => {
        const out: PrjFileEntry[] = [];
        for (const e of entries) {
            if (e.disabled) {
                continue;
            }
            const abs = resolvePath(e.path, info.dir);
            if (!abs) {
                continue;
            }
            // 工程文件可能登记了已删除的文件，这里以磁盘实际存在为准
            if (!fs.existsSync(abs)) {
                continue;
            }
            out.push({ path: abs, disabled: false });
        }
        return out;
    };
    return {
        ...info,
        srcFiles: conv(info.srcFiles),
        simFiles: conv(info.simFiles),
        dataFiles: conv(info.dataFiles),
        ipFiles: conv(info.ipFiles),
    };
}

/**
 * @description 在若干候选目录中查找工程文件（.al 或 .xpr），返回找到的第一个。
 */
function findProjectFile(candidates: AbsPath[], ext: string): AbsPath | undefined {
    for (const dir of candidates) {
        if (!dir || !fs.existsSync(dir) || !fs.statSync(dir).isDirectory()) {
            continue;
        }
        // 直接在目录下找；找不到再向下搜一层，覆盖 prj/anlogic/*.al 这类结构
        const direct = fs.readdirSync(dir).filter(f => f.toLowerCase().endsWith(ext));
        if (direct.length === 1) {
            return hdlPath.join(dir, direct[0]);
        }
        for (const sub of fs.readdirSync(dir)) {
            const subPath = hdlPath.join(dir, sub);
            try {
                if (!fs.statSync(subPath).isDirectory()) {
                    continue;
                }
            } catch {
                continue;
            }
            const nested = fs.readdirSync(subPath).filter(f => f.toLowerCase().endsWith(ext));
            if (nested.length === 1) {
                return hdlPath.join(subPath, nested[0]);
            }
        }
    }
    return undefined;
}

/**
 * @description 工程文件解析器。按 toolChain 定位并解析 .al / .xpr，
 *              结果缓存，仅在工程文件内容变化时重新解析。
 */
class ProjectFileManager {
    private cache?: PrjFileInfo;
    private cacheKey?: string;

    /**
     * @description 解析当前工程文件。未找到或解析失败返回 undefined，
     *              调用方应回退到原有的目录扫描逻辑。
     * @param toolChain 当前工具链（anlogic/xilinx/...）
     * @param searchDirs 候选搜索目录，按优先级排列
     */
    public parse(toolChain: string, searchDirs: AbsPath[], prjFilePath?: AbsPath): PrjFileInfo | undefined {
        let file: AbsPath | undefined;

        if (prjFilePath) {
            // 显式指定了工程文件
            file = fs.existsSync(prjFilePath) ? prjFilePath : undefined;
        } else if (toolChain === 'anlogic') {
            file = findProjectFile(searchDirs, '.al');
        } else if (toolChain === 'xilinx') {
            file = findProjectFile(searchDirs, '.xpr');
        }

        if (!file) {
            return undefined;
        }

        // 缓存键包含修改时间，工程文件变动后可自动失效
        let key: string;
        try {
            key = `${file}:${fs.statSync(file).mtimeMs}`;
        } catch {
            return undefined;
        }
        if (this.cacheKey === key && this.cache) {
            return this.cache;
        }

        try {
            const content = fs.readFileSync(file, { encoding: 'utf-8' });
            if (!isWellFormed(content)) {
                MainOutput.report(`工程文件不完整或格式非法，已忽略：${file}`, { level: ReportType.Warn });
                return undefined;
            }
            const dir = hdlPath.toSlash(fspath.dirname(file));
            const parsed = file.toLowerCase().endsWith('.al')
                ? parseAl(content, file, dir)
                : parseXpr(content, file, dir);
            const info = normalize(parsed);

            this.cache = info;
            this.cacheKey = key;

            MainOutput.report(
                `解析工程文件 ${file}：src ${info.srcFiles.length} 个，sim ${info.simFiles.length} 个，` +
                `IP ${info.ipFiles.length} 个，约束 ${info.dataFiles.length} 个，` +
                `顶层 ${info.topModuleSrc || '(未登记)'}`,
                { level: ReportType.Info }
            );

            return info;
        } catch (error) {
            MainOutput.report(`解析工程文件失败 ${file}: ${error}`, { level: ReportType.Error });
            return undefined;
        }
    }

    /**
     * @description 清空缓存，供工程文件变更或重新 Launch 时调用
     */
    public invalidate(): void {
        this.cache = undefined;
        this.cacheKey = undefined;
    }
}

const projectFileManager = new ProjectFileManager();

/**
 * @description 依据当前 toolChain 与配置推导工程文件的候选搜索目录（按优先级排列）。
 *              anlogic 优先用 digital-ide.prj.anlogic.project.path，
 *              xilinx 用 arch.prjPath 下的 xilinx 子目录。
 */
function candidateDirs(): AbsPath[] {
    const toolChain = opeParam.prjInfo.toolChain;
    const dirs: AbsPath[] = [];

    if (toolChain === 'anlogic') {
        const configured = vscode.workspace
            .getConfiguration('digital-ide.prj.anlogic.project')
            .get<string>('path') || '';
        if (configured) {
            dirs.push(fspath.isAbsolute(configured)
                ? hdlPath.toSlash(configured)
                : hdlPath.join(opeParam.workspacePath, configured));
        }
        dirs.push(hdlPath.join(opeParam.prjInfo.prjPath, 'anlogic'));
    } else if (toolChain === 'xilinx') {
        dirs.push(hdlPath.join(opeParam.prjInfo.prjPath, 'xilinx'));
        dirs.push(opeParam.prjInfo.prjPath);
    }

    return dirs;
}

/**
 * @description 读取当前工程的工程文件信息（同步，结果有缓存）。
 *
 *              优先使用「激活工程」——工作区中可能有多个工程（.al / .xpr），
 *              同一时间只有一个生效，综合、实现、模块树都以它为准。
 *              找不到激活工程时回退到按工具链搜索候选目录。
 */
export function getProjectFileInfo(): PrjFileInfo | undefined {
    try {
        const active = getActiveProjectFile();
        if (active) {
            const info = parseProjectFileByPath(active);
            if (info) {
                return info;
            }
        }
        // 兜底：工作区内没有可解析的工程时，沿用原有的目录搜索逻辑
        return projectFileManager.parse(opeParam.prjInfo.toolChain, candidateDirs());
    } catch (error) {
        MainOutput.report(`读取工程文件失败: ${error}`, { level: ReportType.Error });
        return undefined;
    }
}

// ============================================================================
// 多工程扫描与激活
// ============================================================================

// 扫描时精确跳过的目录名
const SCAN_SKIP_NAMES = new Set<string>([
    '.git', '.svn', '.hg', 'node_modules', '__pycache__', '.vscode-test',
]);

// 扫描时跳过的目录名（正则）。这些是厂商工具生成的中间产物目录，
// 其中可能残留工程文件副本，进入扫描既慢又容易产生重复工程。
const SCAN_SKIP_RE = /(_Runs|_Runs\.bak.*|\.gen|\.runs|\.hw|\.ip_user_files|\.sim|\.srcs|\.cache|\.Xil|\.jobs|netlist)$/i;

// 工程文件搜索的最大深度，避免在深层生成物中浪费时间
const SCAN_MAX_DEPTH = 10;

// 扫描结果缓存时长。树的构建会在一次渲染中连续调用，短 TTL 足够，
// 同时又能及时感知用户新建或删除工程。
const SCAN_TTL_MS = 3000;

let scanCache: { files: AbsPath[], time: number } | undefined;

/**
 * @description 扫描工作区内全部工程文件（.al / .xpr）。
 *              结果按路径排序并缓存 SCAN_TTL_MS，保证树的顺序稳定。
 */
export function findAllProjectFiles(force: boolean = false): AbsPath[] {
    const now = Date.now();
    if (!force && scanCache && now - scanCache.time < SCAN_TTL_MS) {
        return scanCache.files;
    }

    const found: AbsPath[] = [];
    const walk = (dir: AbsPath, depth: number) => {
        if (depth > SCAN_MAX_DEPTH) {
            return;
        }
        let entries: fs.Dirent[];
        try {
            entries = fs.readdirSync(dir, { withFileTypes: true });
        } catch {
            return;
        }
        for (const entry of entries) {
            const full = hdlPath.toSlash(fspath.join(dir, entry.name)) as AbsPath;
            if (entry.isDirectory()) {
                if (SCAN_SKIP_NAMES.has(entry.name) || SCAN_SKIP_RE.test(entry.name)) {
                    continue;
                }
                walk(full, depth + 1);
            } else {
                const lower = entry.name.toLowerCase();
                if (lower.endsWith('.al') || lower.endsWith('.xpr')) {
                    found.push(full);
                }
            }
        }
    };

    walk(opeParam.workspacePath, 0);
    found.sort((a, b) => a.localeCompare(b));

    scanCache = { files: found, time: now };
    MainOutput.report(`扫描到 ${found.length} 个工程文件`, { level: ReportType.Info });
    return found;
}

// 工程文件绝对路径 -> 解析结果。缓存键含 mtime，工程文件改动后自动失效。
const projectFileCache = new Map<AbsPath, { key: string, info: PrjFileInfo | undefined }>();

/**
 * @description 解析任意一个工程文件（.al / .xpr）。与 getProjectFileInfo 的
 *              区别在于不依赖激活状态，供模块树一次列出全部工程。
 */
export function parseProjectFileByPath(file: AbsPath): PrjFileInfo | undefined {
    let key: string;
    try {
        key = `${file}:${fs.statSync(file).mtimeMs}`;
    } catch {
        projectFileCache.delete(file);
        return undefined;
    }

    const cached = projectFileCache.get(file);
    if (cached && cached.key === key) {
        return cached.info;
    }

    let info: PrjFileInfo | undefined;
    try {
        const content = fs.readFileSync(file, { encoding: 'utf-8' });
        if (!isWellFormed(content)) {
            // 截断或非法的工程文件：报出来但不进缓存，用户修好后无需手动刷新
            MainOutput.report(`工程文件不完整或格式非法，已忽略：${file}`, { level: ReportType.Warn });
            return undefined;
        }
        const dir = hdlPath.toSlash(fspath.dirname(file));
        const parsed = file.toLowerCase().endsWith('.al')
            ? parseAl(content, file, dir)
            : parseXpr(content, file, dir);
        info = normalize(parsed);
    } catch (error) {
        MainOutput.report(`解析工程文件失败 ${file}: ${error}`, { level: ReportType.Error });
        info = undefined;
    }

    projectFileCache.set(file, { key, info });
    return info;
}

/**
 * @description 当前激活的工程文件。
 *
 *              取自配置 digital-ide.prj.activeProjectFile；该值为空或指向的
 *              文件已不存在时，退化为扫描结果中的第一个工程，保证总有一个
 *              激活工程可用。
 */
export function getActiveProjectFile(): AbsPath | undefined {
    const configured = vscode.workspace
        .getConfiguration('digital-ide.prj')
        .get<string>('activeProjectFile') || '';

    const files = findAllProjectFiles();
    if (configured) {
        const key = normalizePathKey(configured);
        const matched = files.find(f => normalizePathKey(f) === key);
        if (matched) {
            return matched;
        }
    }
    return files[0];
}

/**
 * @description 设置激活工程，写入工作区配置以便下次打开时保持
 */
export async function setActiveProjectFile(file: AbsPath): Promise<void> {
    await vscode.workspace
        .getConfiguration('digital-ide.prj')
        .update('activeProjectFile', hdlPath.toSlash(file), vscode.ConfigurationTarget.Workspace);
}

/**
 * @description 全部工程的解析结果，附带激活标记，供模块树逐工程渲染
 */
export function getAllProjectFileInfos(): { info: PrjFileInfo, active: boolean }[] {
    const active = getActiveProjectFile();
    const activeKey = active ? normalizePathKey(active) : '';

    const result: { info: PrjFileInfo, active: boolean }[] = [];
    for (const file of findAllProjectFiles()) {
        const info = parseProjectFileByPath(file);
        if (info) {
            result.push({ info, active: normalizePathKey(file) === activeKey });
        }
    }
    return result;
}

/**
 * @description 使工程扫描与解析缓存失效。新建 / 删除工程、工程文件内容变化
 *              或用户手动刷新时调用。
 */
export function invalidateProjectFileCache(): void {
    scanCache = undefined;
    projectFileCache.clear();
    projectFileManager.invalidate();
}

/**
 * @description 路径归一化用于集合比对：Windows 下大小写不敏感，统一小写并统一分隔符。
 */
export function normalizePathKey(path: AbsPath): string {
    const p = hdlPath.toSlash(path);
    return process.platform === 'win32' ? p.toLowerCase() : p;
}

export { projectFileManager };
