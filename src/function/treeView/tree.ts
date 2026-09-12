import * as vscode from 'vscode';
import * as fspath from 'path';

import { AbsPath, MainOutput, opeParam, ReportType } from '../../global';
import { SimPath, SrcPath } from '../../global/prjInfo';
import { HdlFile, HdlInstance, hdlParam } from '../../hdlParser/core';
import { HdlFileProjectType, Range } from '../../hdlParser/common';
import { hdlFile, hdlPath } from '../../hdlFs';
import { xilinx, itemModes, otherModes } from './common';
import { getIconConfig } from '../../hdlFs/icons';
import { DoFastFileType } from '../../global/lsp';
import { t } from '../../i18n';
import { ToolChainType } from '../../global/enum';
import {
    getAllProjectFileInfos,
    getActiveProjectFile,
    getProjectFileInfo,
    invalidateProjectFileCache,
    parseProjectFileByPath,
    normalizePathKey,
    setActiveProjectFile,
    PrjFileEntry,
    PrjFileInfo
} from '../../manager/projectFile';

/**
 * @description 节点角色。未设置表示模块 / 例化节点，沿用既有行为。
 *  prj   —— 工程根，标签为工程名与器件型号
 *  group —— 分类根（src / sim / 约束）
 *  dir   —— 目录节点，由工程登记文件的路径前缀折叠而来
 *  file  —— 工程登记的源文件
 */
type NodeRole = 'prj' | 'group' | 'dir' | 'file';

interface ModuleDataItem {
    icon: string,           // 图标
    name: string,           // module name / 目录名 / 文件名 / 工程名
    type: string,
    doFastFileType: DoFastFileType | undefined,
    range: Range | undefined,
    path: AbsPath | undefined,      // path of the file
    parent: ModuleDataItem | undefined,   // parent file
    role?: NodeRole,                // 节点角色，见 NodeRole
    children?: ModuleDataItem[],    // 工程根 / 分类 / 目录 / 文件的子节点，构造时一次性展开
    tip?: string,                   // 悬停提示，未设置时回退为 path
    active?: boolean                // 工程根专用：是否为当前激活工程
}

// 旧结构（非工程树）下顶层模块缓存的键
const LEGACY_PRJ_KEY = '__legacy__';

interface FirstTopItem {
    name: string,
    path: AbsPath | undefined
}

interface FirstTop {
    src: FirstTopItem | null,
    sim: FirstTopItem | null
}

function canExpandable(element: ModuleDataItem) {
    // 工程根 / 分类 / 目录 / 文件节点的子节点在构造时已确定，按实际数量判定
    if (element.role !== undefined) {
        return (element.children?.length ?? 0) > 0;
    }
    if (element.icon === 'src' || element.icon === 'sim') {     // src and sim can expand anytime
        return true;
    } else {
        const modulePath = element.path;
        if (!modulePath) {                              // unsolved module cannot expand
            return false;
        }
        const moduleName = element.name;
        if (!hdlParam.hasHdlModule(modulePath, moduleName)) {      // test or bug
            return false;
        }
        const module = hdlParam.getHdlModule(modulePath, moduleName);
        if (module) {
            return module.getInstanceNum() > 0;
        } else {
            return false;
        }
    }
}


class ModuleTreeProvider implements vscode.TreeDataProvider<ModuleDataItem> {
    _onDidChangeTreeData: vscode.EventEmitter<ModuleDataItem>;
    onDidChangeTreeData: vscode.Event<ModuleDataItem>;
    srcRootItem: ModuleDataItem;
    simRootItem: ModuleDataItem;
    dataRootItem: ModuleDataItem;
    // 工程根节点，key 为工程文件绝对路径。工作区可有多个工程，逐一建树。
    prjRootItems: Map<AbsPath, ModuleDataItem> = new Map();
    // 各工程的顶层模块缓存。不同工程的顶层互不相同，必须按工程隔离，
    // 否则后构建的工程会覆盖前一个，导致顶层图标标错。
    private firstTopByProject: Map<AbsPath, FirstTop> = new Map();
    // 归一化路径 -> HdlFile。工程文件里登记的路径与 LSP 解析出的路径
    // 在盘符大小写上未必一致，直接查表会漏，因此统一按归一化键索引。
    private hdlFileByKey: Map<string, HdlFile> | undefined;

    constructor() {
        this._onDidChangeTreeData = new vscode.EventEmitter<ModuleDataItem>();
        this.onDidChangeTreeData = this._onDidChangeTreeData.event;

        // 下面三个分类节点只在「非工程树」的旧结构中作为根使用
        this.srcRootItem = {
            icon: 'src',
            type: HdlFileProjectType.Src,
            doFastFileType: undefined,
            name: 'src',
            range: undefined,
            path: '',
            parent: undefined
        };

        this.simRootItem = {
            icon: 'sim',
            type: HdlFileProjectType.Sim,
            doFastFileType: undefined,
            name: 'sim',
            range: undefined,
            path: '',
            parent: undefined
        };

        this.dataRootItem = {
            icon: 'tcl',
            type: 'data',
            doFastFileType: undefined,
            name: t('treeview.constraint'),
            range: undefined,
            path: '',
            parent: undefined
        };
    }

    /**
     * @description 工程树的子节点在构造时展开并缓存在节点上，因此刷新前
     *              必须先重建一次，否则 getChildren 会返回上一次的旧节点。
     */
    private rebuildProjectTree() {
        this.buildRootItems();
    }

    public refresh(element?: ModuleDataItem) {
        if (element) {
            this._onDidChangeTreeData.fire(element);
            return;
        }
        this.rebuildProjectTree();
        // 根节点集合可能整体变化（新建 / 删除工程），一律整体刷新
        this._onDidChangeTreeData.fire(undefined as unknown as ModuleDataItem);
    }

    /**
     * @description 刷新工程根（工程文件登记内容变化或激活工程切换后调用）
     */
    public refreshPrj() {
        this.refresh();
    }

    public refreshSrc() {
        this.refresh();
    }

    public refreshSim() {
        this.refresh();
    }


    public getTreeItem(element: ModuleDataItem): vscode.TreeItem | Thenable<vscode.TreeItem> {
        let itemName = element.name;
        // 文件 / 目录节点的 name 就是文件名，不需要模块类型的括号修饰
        if (element.role === undefined && itemModes.has(element.icon)) {
            itemName = `${element.type}(${itemName})`;
        }
        const expandable = canExpandable(element);
        let collapsibleState = vscode.TreeItemCollapsibleState.None;
        if (expandable) {
            // 工程根与分类默认展开，目录与文件默认折叠，模块节点沿用原有规则
            if (element.role === 'prj' || element.role === 'group' || element.parent === undefined) {
                collapsibleState = vscode.TreeItemCollapsibleState.Expanded;
            } else {
                collapsibleState = vscode.TreeItemCollapsibleState.Collapsed;
            }
        }

        const treeItem = new vscode.TreeItem(itemName, collapsibleState);

        // set contextValue
        // 文件节点的 name 是文件名而非模块名，因此使用单独的 hdlfile，
        // 避免误匹配针对模块节点的仿真 / 网表 / 设顶层等菜单
        if (element.role === 'prj') {
            // 激活工程与其它工程区分开，菜单与描述文字据此变化
            treeItem.contextValue = element.active ? 'prjActive' : 'prjInactive';
            if (element.active) {
                treeItem.description = t('treeview.project.active');
            }
        } else if (element.role === 'file') {
            treeItem.contextValue = 'hdlfile';
        } else if (element.role !== undefined) {
            treeItem.contextValue = element.role;
        } else if (otherModes.has(element.icon)) {
            treeItem.contextValue = 'other';
        } else {
            treeItem.contextValue = 'file';
        }

        // set tooltip
        treeItem.tooltip = element.tip ?? element.path;
        if (!treeItem.tooltip) {
            treeItem.tooltip = 'src';
        }

        // set iconPath
        treeItem.iconPath = getIconConfig(element.icon);

        // set command：目录 / 工程根 / 分类节点只负责展开，不打开文件
        if (element.role === undefined || element.role === 'file') {
            treeItem.command = {
                title: "Open this HDL File",
                command: 'digital-ide.treeView.arch.openFile',
                arguments: [element.path, element.range, element],
            };
        }

        return treeItem;
    }

    public getChildren(element?: ModuleDataItem | undefined): vscode.ProviderResult<ModuleDataItem[]> {
        if (element) {
            // 工程根 / 分类 / 目录 / 文件节点的子节点已在构造时展开
            if (element.role !== undefined) {
                return element.children ?? [];
            }

            const name = element.name;

            if (name === 'sim' || name === 'src') {
                element.parent = undefined;
                return this.getTopModuleItemList(element);
            } else {
                return this.getInstanceItemList(element);
            }
        } else {
            return this.buildRootItems();
        }
    }

    public getParent(element: ModuleDataItem): vscode.ProviderResult<ModuleDataItem> {
        return element.parent;
    }

    /**
     * @description 按工程文件（.al / .xpr）登记的文件过滤顶层模块列表。
     *
     *              目的：工作区中往往并存多个工程与大量 testbench，而模块树会把所有
     *              未被实例化的模块都列为顶层，导致列表被无关文件淹没。这里只保留
     *              工程文件登记过的文件所属模块，使树与工程实际编译内容一致。
     *
     *              注意：仅影响模块树的展示。LSP 仍解析全部文件，因此未登记的
     *              testbench 等仍可正常跳转、补全、悬停。
     *
     *              当该分类没有登记信息时不过滤（例如安路 .al 不登记 testbench，
     *              仿真区保持原样），避免把内容误清空。
     */
    private filterByProjectFile(modules: ReturnType<typeof hdlParam.getTopModulesByType>, type: string) {
        const enabled = vscode.workspace
            .getConfiguration('digital-ide.prj.file.scope')
            .get<boolean>('treeOnly', true);
        if (!enabled) {
            return modules;
        }

        const prjFileInfo = getProjectFileInfo();
        if (!prjFileInfo) {
            return modules;
        }

        const registered = type === 'src' ? prjFileInfo.srcFiles : prjFileInfo.simFiles;
        if (registered.length === 0) {
            return modules;
        }

        const allowed = new Set(registered.map(entry => normalizePathKey(entry.path)));
        const kept = modules.filter(module => module.path && allowed.has(normalizePathKey(module.path)));

        // 过滤后为空说明登记信息与实际解析结果不匹配（例如路径大小写或分隔符差异），
        // 此时退回完整列表，宁多勿少。
        return kept.length > 0 ? kept : modules;
    }

    /**
     * @description 是否启用「以工程为根、按工程登记文件展开」的树结构。
     *              需要工程文件（.al / .xpr）可解析，否则自动回退到旧的 src/sim 结构。
     */
    private useProjectTree(): boolean {
        return vscode.workspace
            .getConfiguration('digital-ide.prj.file.scope')
            .get<boolean>('projectRoot', true);
    }

    /**
     * @description 未启用工程树时，把分类根还原为旧的按模块例化展开的形式
     */
    private resetToLegacyRoots(): ModuleDataItem[] {
        this.prjRootItems.clear();
        for (const root of [this.srcRootItem, this.simRootItem]) {
            root.role = undefined;
            root.children = undefined;
            root.parent = undefined;
        }
        return [this.srcRootItem, this.simRootItem];
    }

    /**
     * @description 构造树的根节点。
     *
     *              工作区中扫描到的每个工程（.al / .xpr）各占一个根节点，
     *              根节点显示工程名与器件型号，其下按 设计 / 仿真 / 约束 分类
     *              列出该工程实际登记的文件。同一时间只有一个工程处于激活态，
     *              它的节点标注「已激活」，综合 / 实现等硬件操作都以它为准。
     *
     *              未启用或未扫描到工程时，回退为 src / sim 两个根。
     */
    private buildRootItems(): ModuleDataItem[] {
        if (!this.useProjectTree()) {
            return this.resetToLegacyRoots();
        }

        const projects = getAllProjectFileInfos();
        if (projects.length === 0) {
            return this.resetToLegacyRoots();
        }

        this.hdlFileByKey = this.buildHdlFileIndex();

        // 激活工程排在最前，便于一眼看到当前生效的工程
        projects.sort((a, b) => Number(b.active) - Number(a.active));

        const roots: ModuleDataItem[] = [];
        const seen = new Set<string>();
        for (const { info, active } of projects) {
            const key = normalizePathKey(info.file);
            if (seen.has(key)) {
                continue;
            }
            seen.add(key);

            const node = this.buildProjectNode(info, active, key);
            if (node) {
                roots.push(node);
            }
        }

        // 清理已不存在的工程，避免缓存里残留节点
        for (const key of [...this.prjRootItems.keys()]) {
            if (!seen.has(key)) {
                this.prjRootItems.delete(key);
            }
        }

        return roots.length > 0 ? roots : this.resetToLegacyRoots();
    }

    /**
     * @description 构造单个工程的根节点及其子树。
     *              复用已缓存的对象，以便按引用刷新时能命中实际树节点。
     */
    private buildProjectNode(info: PrjFileInfo, active: boolean, key: string): ModuleDataItem | undefined {
        const label = this.makeProjectLabel(info);
        const tool = info.kind === 'al' ? '安路 TD' : 'Xilinx Vivado';
        const tip = `${tool} 工程\n${info.file}` + (active ? '\n（当前激活）' : '');

        let prjRoot = this.prjRootItems.get(key);
        if (!prjRoot) {
            prjRoot = {
                icon: 'library',
                name: label,
                type: 'prj',
                doFastFileType: undefined,
                range: undefined,
                path: info.file,
                parent: undefined,
                role: 'prj',
                children: [],
            };
            this.prjRootItems.set(key, prjRoot);
        }

        // 激活工程换用醒目的图标，与普通工程区分
        prjRoot.icon = active ? 'current-src-top' : 'library';
        prjRoot.name = label;
        prjRoot.type = 'prj';
        prjRoot.path = info.file;
        prjRoot.tip = tip;
        prjRoot.role = 'prj';
        prjRoot.active = active;

        const firstTop = this.firstTopOf(info.file);
        const groups: ModuleDataItem[] = [];
        const candidates: [string, string, string, PrjFileEntry[]][] = [
            ['src', HdlFileProjectType.Src, 'src', info.srcFiles],
            ['sim', HdlFileProjectType.Sim, 'sim', info.simFiles],
            [t('treeview.ip'), 'ip', 'ip', info.ipFiles],
            [t('treeview.constraint'), 'data', 'tcl', info.dataFiles],
        ];
        for (const [name, type, icon, files] of candidates) {
            const group = this.buildGroupItem(name, type, icon, files, prjRoot, info.file, firstTop, active);
            if (group) {
                groups.push(group);
            }
        }

        prjRoot.children = groups;
        return prjRoot;
    }

    /**
     * @description 切换激活工程：写入配置、同步器件与工具链、重建树。
     *              硬件相关操作（综合 / 实现 / 下载）随后都作用于该工程。
     */
    public async activateProject(item: ModuleDataItem) {
        const file = item.path;
        if (!file || item.role !== 'prj') {
            return;
        }
        if (item.active) {
            vscode.window.showInformationMessage(t('info.treeview.project.already-active', item.name));
            return;
        }

        await setActiveProjectFile(file);
        invalidateProjectFileCache();

        // 器件与工具链必须随工程切换，否则综合会用错器件型号或工具链
        const info = parseProjectFileByPath(file);
        if (info) {
            opeParam.prjInfo.updateDevice(info.device);
            opeParam.prjInfo.updateToolChain(info.kind === 'al' ? ToolChainType.Anlogic : ToolChainType.Xilinx);
        }

        MainOutput.report(`激活工程：${file}`, { level: ReportType.Run });
        this.refresh();
    }

    /**
     * @description 取指定工程的顶层模块缓存
     */
    private firstTopOf(prjFile: AbsPath): FirstTop {
        let firstTop = this.firstTopByProject.get(prjFile);
        if (!firstTop) {
            firstTop = { src: null, sim: null };
            this.firstTopByProject.set(prjFile, firstTop);
        }
        return firstTop;
    }

    /**
     * @description 激活工程的顶层缓存，供旧结构与不区分工程的路径使用
     */
    private get firstTop(): FirstTop {
        return this.firstTopOf(getActiveProjectFile() ?? LEGACY_PRJ_KEY);
    }

    /**
     * @description 把顶层模块同步到 opeParam，供综合 / 仿真等流程使用
     */
    private writeFirstTopToOpe(type: keyof FirstTop, item: FirstTopItem) {
        if (type === 'src') {
            opeParam.firstSrcTopModule.name = item.name;
            opeParam.firstSrcTopModule.path = item.path;
        } else if (type === 'sim') {
            opeParam.firstSimTopModule.name = item.name;
            opeParam.firstSimTopModule.path = item.path;
        }
    }

    /**
     * @description 工程根标签：工程名 + 器件型号，如 pxf100 (PH1A90SEG325)
     */
    private makeProjectLabel(info: PrjFileInfo): string {
        const name = fspath.basename(info.file, hdlPath.extname(info.file, true));
        const device = info.device || opeParam.prjInfo.device;
        return device ? `${name} (${device})` : name;
    }

    /**
     * @description 构造一个分类节点。该分类下没有登记文件时返回 undefined，
     *              避免树里出现空节点（例如 .al 不登记 testbench，仿真分类即隐藏）。
     *              分类节点逐工程新建，不能共用单例，否则多个工程会互相覆盖子节点。
     */
    private buildGroupItem(
        name: string,
        type: string,
        icon: string,
        files: PrjFileEntry[],
        prjRoot: ModuleDataItem,
        prjFile: AbsPath,
        firstTop: FirstTop,
        active: boolean
    ): ModuleDataItem | undefined {
        if (files.length === 0) {
            return undefined;
        }

        const group: ModuleDataItem = {
            icon,
            name,
            type,
            doFastFileType: undefined,
            range: undefined,
            path: prjFile,
            parent: prjRoot,
            role: 'group',
            tip: `${files.length} 个文件`,
            children: [],
        };

        // 先确定顶层模块，文件节点内的模块图标才能标出当前顶层
        if (type === HdlFileProjectType.Src || type === HdlFileProjectType.Sim) {
            this.ensureFirstTop(type as keyof FirstTop, prjFile, firstTop, active);
        }

        group.children = this.buildFileNodes(files, type, group, firstTop);
        return group.children.length > 0 ? group : undefined;
    }

    /**
     * @description 按工程登记的文件构造目录 / 文件节点。
     *
     *              先把绝对路径相对所有文件的共同祖先目录求相对路径，再按 '/'
     *              逐段建树、同名目录合并。于是 ../px100_src/regs_0.v 这类登记
     *              显示为 px100_src/regs_0.v，与 GUI 的工程文件树一致。
     */
    private buildFileNodes(files: PrjFileEntry[], type: string, parent: ModuleDataItem, firstTop: FirstTop): ModuleDataItem[] {
        const base = this.commonDir(files.map(entry => entry.path));
        const dirMap = new Map<string, ModuleDataItem>();
        const roots: ModuleDataItem[] = [];

        for (const entry of files) {
            const rel = hdlPath.toPureRelativePath(hdlPath.relative(base, entry.path));
            const segments = rel.split('/').filter(segment => segment.length > 0);
            if (segments.length === 0) {
                continue;
            }

            let dirPath = base;
            let container = roots;
            let containerParent = parent;

            for (let i = 0; i < segments.length - 1; i++) {
                dirPath = hdlPath.join(dirPath, segments[i]);
                let dirItem = dirMap.get(dirPath);
                if (!dirItem) {
                    dirItem = {
                        icon: 'list-tree',
                        name: segments[i],
                        type,
                        doFastFileType: undefined,
                        range: undefined,
                        path: dirPath,
                        parent: containerParent,
                        role: 'dir',
                        tip: dirPath,
                        children: [],
                    };
                    dirMap.set(dirPath, dirItem);
                    container.push(dirItem);
                }
                container = dirItem.children!;
                containerParent = dirItem;
            }

            const fileItem: ModuleDataItem = {
                icon: this.judgeFileIcon(entry.path),
                name: segments[segments.length - 1],
                type,
                doFastFileType: undefined,
                range: undefined,
                path: entry.path,
                parent: containerParent,
                role: 'file',
                tip: entry.path,
                children: [],
            };
            fileItem.children = this.getFileModuleItems(fileItem, type, firstTop);
            container.push(fileItem);
        }

        this.sortFileNodes(roots);
        return roots;
    }

    /**
     * @description 建立归一化路径到 HdlFile 的索引，供文件节点查找其定义模块
     */
    private buildHdlFileIndex(): Map<string, HdlFile> {
        const map = new Map<string, HdlFile>();
        for (const file of hdlParam.getAllHdlFiles()) {
            map.set(normalizePathKey(file.path), file);
        }
        return map;
    }

    /**
     * @description 某个源文件内定义的模块列表，作为文件节点的子节点。
     *
     *              type 沿用 src / sim，使 getItemType 仍能自下而上定位分类；
     *              节点形状与旧的顶层模块一致，仿真 / 网表 / 设顶层等命令无需改动。
     */
    private getFileModuleItems(fileItem: ModuleDataItem, type: string, firstTop: FirstTop): ModuleDataItem[] {
        const path = fileItem.path;
        if (!path) {
            return [];
        }

        // IP 的 .xml / .ipc 等非 HDL 文件不在 hdlParam 中，表现为无子节点的叶文件
        const hdlFileObj = this.hdlFileByKey?.get(normalizePathKey(path));
        if (!hdlFileObj) {
            return [];
        }

        const items = hdlFileObj.getAllHdlModules().map<ModuleDataItem>(module => ({
            icon: this.judgeTopModuleIconByDoFastType(hdlFileObj.doFastType),
            type,
            doFastFileType: hdlFileObj.doFastType,
            name: module.archName === undefined ? module.name : `${module.name}(${module.archName})`,
            range: module.range,
            path: module.path,
            parent: fileItem,
        }));

        if (items.length === 0) {
            return items;
        }

        items.sort((a, b) => a.name.localeCompare(b.name));

        if (type === HdlFileProjectType.Src || type === HdlFileProjectType.Sim) {
            return this.promoteFirstTop(items, type as keyof FirstTop, firstTop);
        }
        return items;
    }

    /**
     * @description 文件节点图标：约束用 tcl 图标，代码文件按扩展名区分语言
     */
    private judgeFileIcon(path: AbsPath): string {
        switch (hdlPath.extname(path, false)) {
            case 'v':
            case 'vh':
                return 'verilog';
            case 'sv':
            case 'svh':
                return 'systemverilog';
            case 'vhd':
            case 'vhdl':
                return 'vhdl';
            case 'adc':
            case 'sdc':
            case 'xdc':
            case 'fdc':
                return 'tcl';
            default:
                return 'file';
        }
    }

    /**
     * @description 求一组文件的共同祖先目录，作为目录树展开的基准
     */
    private commonDir(paths: AbsPath[]): AbsPath {
        let base = hdlPath.toSlash(fspath.dirname(paths[0]));
        for (const path of paths) {
            const dir = hdlPath.toSlash(fspath.dirname(path));
            while (dir !== base && !dir.startsWith(base + '/')) {
                const parent = hdlPath.toSlash(fspath.dirname(base));
                if (parent === base) {
                    return base;
                }
                base = parent;
            }
        }
        return base;
    }

    /**
     * @description 目录在前、文件在后，各自按名称排序，与常见文件浏览器一致
     */
    private sortFileNodes(items: ModuleDataItem[]) {
        items.sort((a, b) => {
            const aRank = a.role === 'dir' ? 0 : 1;
            const bRank = b.role === 'dir' ? 0 : 1;
            if (aRank !== bRank) {
                return aRank - bRank;
            }
            return a.name.localeCompare(b.name);
        });
        for (const item of items) {
            if (item.role === 'dir' && item.children && item.children.length > 0) {
                this.sortFileNodes(item.children);
            }
        }
    }

    /**
     * @description 计算并缓存指定分类的顶层模块。
     *
     *              优先采用工程文件登记的顶层（.al 的 TOP_MODULE、.xpr 的
     *              FileSet Config/TopModule）；否则退化为依赖最多的模块。
     *              后者在依赖数相同时按遍历顺序决定——例如 px100_top 与
     *              pxf100_top 的依赖集合完全一致，因此登记值必须优先。
     *
     *              每个工程各自缓存一份，互不干扰；只有激活工程的顶层会
     *              写入 opeParam，供综合、仿真等流程使用。
     */
    private ensureFirstTop(
        type: keyof FirstTop,
        prjFile: AbsPath,
        firstTop: FirstTop,
        active: boolean
    ): FirstTopItem | null {
        const cached = firstTop[type];
        if (cached?.name) {
            return cached;
        }

        const topModules = hdlParam.getTopModulesByType(type);

        let computed: FirstTopItem | null = null;

        const info = parseProjectFileByPath(prjFile);
        const registeredTop = type === 'src' ? info?.topModuleSrc : info?.topModuleSim;
        if (registeredTop) {
            const matched = topModules.find(m => m.name === registeredTop);
            if (matched) {
                computed = { path: matched.path, name: matched.name };
            }
        }

        if (!computed) {
            let maxDepSize = 0;
            for (const hdlModule of topModules) {
                const deps = hdlParam.getAllDependences(hdlModule.path, hdlModule.name);
                if (!deps) {
                    continue;
                }
                const depSize = deps.include.length + deps.others.length;
                if (depSize > maxDepSize) {
                    maxDepSize = depSize;
                    computed = { path: hdlModule.path, name: hdlModule.name };
                }
            }
        }

        if (!computed) {
            return null;
        }

        firstTop[type] = computed;

        // 只有激活工程才写入 opeParam：综合 / 仿真等流程读的是它
        if (active) {
            this.writeFirstTopToOpe(type, computed);
        }
        return computed;
    }

    /**
     * @description 把列表中的当前顶层移到首位并换用专用图标
     */
    private promoteFirstTop(items: ModuleDataItem[], type: keyof FirstTop, firstTop: FirstTop): ModuleDataItem[] {
        const current = firstTop[type];
        if (!current) {
            return items;
        }
        const dataItem = items.find(item => item.name === current.name && item.path === current.path);
        if (!dataItem) {
            return items;
        }
        dataItem.icon = this.makeFirstTopIconName(type);
        return [dataItem, ...items.filter(item => item !== dataItem)];
    }

    public getTopModuleItemList(element: ModuleDataItem): ModuleDataItem[] {
        // src or sim
        const moduleType = element.name as keyof (SrcPath & SimPath);

        // 获取所有对应类型（src | sim）下的顶层模块数量，并按工程文件登记范围收敛
        const topModules = this.filterByProjectFile(hdlParam.getTopModulesByType(moduleType), moduleType);
        
        // 将所有顶层模块转换成 ModuleDataItem 自定义 treeview item 数据结构
        let topModuleItemList = topModules.map<ModuleDataItem>(module => ({
            icon: this.judgeTopModuleIconByDoFastType(module.file.doFastType),
            type: moduleType,
            doFastFileType: module.file.doFastType,
            name: module.archName === undefined ? module.name : `${module.name}(${module.archName})`,
            range: module.range,
            path: module.path,
            parent: element,
        }));

        // 根据字母序列进行排序
        topModuleItemList.sort((a, b) => a.name.localeCompare(b.name));

        if (topModuleItemList.length === 0) {
            return topModuleItemList;
        }

        const type = moduleType as keyof FirstTop;
        const firstTop = this.firstTop;
        this.ensureFirstTop(type, getActiveProjectFile() ?? LEGACY_PRJ_KEY, firstTop, true);
        return this.promoteFirstTop(topModuleItemList, type, firstTop);
    }

    // 获取当前模块下的子模块
    public getInstanceItemList(element: ModuleDataItem): ModuleDataItem[] {
        if (!element.path) {
            return [];
        }
        
        const moduleDataItemList: ModuleDataItem[] = [];
        const targetModule = hdlParam.getHdlModule(element.path, element.name);
        
        if (targetModule) {
            const allInstances = targetModule.getAllInstances();            
            // 根据出现次序进行排序
            allInstances.sort((a, b) => a.range.start.line - b.range.start.line);
            for (const instance of allInstances) {
                // 所有的例化模块都定向到它的定义文件上
                const item: ModuleDataItem = {
                    icon: 'file',
                    type: instance.name,
                    name: instance.type,
                    range: instance.module?.range,
                    path: instance.module?.path,
                    parent: element,
                    doFastFileType: instance.getDoFastFileType
                };

                if (item.type === element.type &&            // 防止递归
                    item.name === element.name &&
                    item.path === element.path) {
                    continue;
                }
                item.icon = this.judgeIcon(item, instance);
                
                moduleDataItemList.push(item);
            }
        } else {
            MainOutput.report(`cannot find ${element} in hdlParam when constructing treeView`, {
                level: ReportType.Error
            });
        }
        
        return moduleDataItemList;
    }

    public setFirstTop(type: keyof FirstTop, name: string, path: AbsPath | undefined) {
        // 设置顶层总是作用于激活工程：菜单只能从激活工程的树节点触发
        const prjFile = getActiveProjectFile() ?? LEGACY_PRJ_KEY;
        this.firstTopOf(prjFile)[type] = { name, path };
        this.writeFirstTopToOpe(type, { name, path });
    }

    private makeFirstTopIconName(type: string): string {
        return 'current-' + type + '-top';
    }

    private judgeIcon(item: ModuleDataItem, instance: HdlInstance): string {
        const workspacePath = opeParam.workspacePath;
        if (instance.module === undefined) {
            return 'File Error';
        }

        if (item.doFastFileType === 'ip') {
            return 'ip';
        } else if (item.doFastFileType === 'primitives') {
            return 'celllib';
        }

        if (hdlPath.exist(item.path)) {
            if (!item.path?.includes(workspacePath)) {
                return 'remote';
            } else {
                const langID = hdlFile.getLanguageId(item.path);
                return langID;
            }
        } else {
            if (xilinx.has(instance.type)) {
                return 'cells';
            } else {
                return 'File Error';
            }
        }
    }

    private judgeTopModuleIconByDoFastType(doFastType: DoFastFileType): string {
        switch (doFastType) {
            case 'common':
                return 'top';
        
            case 'ip':
                return 'ip';
            case 'primitives':
                return 'celllib';
        }
        return 'top';
    }

    public getItemType(item: ModuleDataItem): string | null {
        if (!item) {
            return null;
        }
        // 自下而上找最近的 src / sim 分类。工程树在模块节点与分类之间插入了
        // 文件 / 目录节点，因此不能像原来那样直接取最顶层节点的 type。
        let currentLevel: ModuleDataItem | undefined = item;
        while (currentLevel) {
            if (currentLevel.type === HdlFileProjectType.Src || currentLevel.type === HdlFileProjectType.Sim) {
                return currentLevel.type;
            }
            currentLevel = currentLevel.parent;
        }
        return null;
    }
}

const moduleTreeProvider = new ModuleTreeProvider();

export {
    moduleTreeProvider,
    ModuleDataItem
};