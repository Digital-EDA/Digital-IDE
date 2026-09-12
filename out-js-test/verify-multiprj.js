/**
 * 多工程扫描 / 解析 / 激活 验证脚本
 *
 * 直接 require 扩展的 tsc 编译产物（out-js/），对 vscode 模块打桩后
 * 调用真实的 projectFile 实现，因此验证的是扩展自身的行为而非复刻逻辑。
 *
 * 用法：
 *   node out-js-test/verify-multiprj.js <待测工作区绝对路径>
 */

const Module = require('module');
const path = require('path');
const fs = require('fs');

const REPO = path.resolve(__dirname, '..');
const WORKSPACE = process.argv[2] || 'D:/fpga_workspace/test_multiprj';

// ---------------------------------------------------------------------------
// vscode 桩
// ---------------------------------------------------------------------------

const configStore = new Map();

const vscodeStub = {
    workspace: {
        workspaceFolders: [{ uri: { fsPath: WORKSPACE } }],
        getConfiguration(section) {
            return {
                get(key) {
                    return configStore.get(`${section}.${key}`);
                },
                async update(key, value) {
                    configStore.set(`${section}.${key}`, value);
                },
            };
        },
        onDidChangeConfiguration() {
            return { dispose() {} };
        },
    },
    window: {
        showInformationMessage(msg) { console.log(`  [info] ${msg}`); },
        showWarningMessage(msg) { console.log(`  [warn] ${msg}`); },
        showErrorMessage(msg) { console.log(`  [error] ${msg}`); },
        createOutputChannel() {
            return { appendLine() {}, append() {}, show() {}, dispose() {} };
        },
    },
    Uri: { file: p => ({ fsPath: p }) },
    EventEmitter: class {
        constructor() { this.event = () => ({ dispose() {} }); }
        fire() {}
        dispose() {}
    },
    TreeItemCollapsibleState: { None: 0, Collapsed: 1, Expanded: 2 },
    ProgressLocation: { Notification: 15 },
    ConfigurationTarget: { Workspace: 2 },
};

const origLoad = Module._load;

// global/index.js 会连带引入 languageclient 等重依赖，其中依赖真实的 vscode
// 运行时类，无法在纯 Node 下加载。这里直接替换成最小实现：被测代码只用到
// opeParam 的 workspacePath 与 prjInfo 的若干字段。
const globalDir = path.join(REPO, 'out-js/global');

const opeParamStub = {
    workspacePath: WORKSPACE,
    extensionPath: REPO,
    os: process.platform,
    dideignorePath: path.join(WORKSPACE, '.dideignore'),
    prjInfo: {
        toolChain: 'xilinx',
        device: '',
        prjPath: path.join(WORKSPACE, 'prj'),
        prjName: { PL: 'test', PS: 'test' },
        arch: {
            prjPath: path.join(WORKSPACE, 'prj'),
            hardware: { src: WORKSPACE, sim: WORKSPACE, data: WORKSPACE },
            software: { src: '', data: '' },
        },
        ipPath: '',
    },
    firstSrcTopModule: { name: null, path: null },
    firstSimTopModule: { name: null, path: null },
    initContextPath(ext, ws) {
        this.extensionPath = ext;
        this.workspacePath = ws;
    },
};

const ReportTypeStub = { Info: 'info', Warn: 'warn', Error: 'error', Run: 'run' };

const outputStub = {
    MainOutput: {
        report(msg, opt) {
            const level = opt && opt.level;
            if (level === ReportTypeStub.Error) {
                console.log(`  [报告:错误] ${msg}`);
            }
        },
        show() {},
    },
    HardwareOutput: { report() {}, show() {} },
    ReportType: ReportTypeStub,
};

const globalStub = {
    opeParam: opeParamStub,
    ReportType: ReportTypeStub,
};

Module._load = function (request, parent, isMain) {
    if (request === 'vscode') {
        return vscodeStub;
    }
    let resolved;
    try {
        resolved = Module._resolveFilename(request, parent, isMain);
    } catch {
        return origLoad.apply(this, arguments);
    }
    if (resolved === path.join(globalDir, 'index.js')) {
        return globalStub;
    }
    if (resolved === path.join(globalDir, 'outputChannel.js')) {
        return outputStub;
    }
    if (resolved === path.join(globalDir, 'prjInfo.js')) {
        return { PrjInfo: class {}, PrjInfoDefaults: {} };
    }
    return origLoad.apply(this, arguments);
};

// ---------------------------------------------------------------------------
// 载入编译产物
// ---------------------------------------------------------------------------

const projectFile = require(path.join(REPO, 'out-js/manager/projectFile.js'));
const hdlPath = require(path.join(REPO, 'out-js/hdlFs/path.js'));

const {
    findAllProjectFiles,
    getActiveProjectFile,
    setActiveProjectFile,
    getAllProjectFileInfos,
    parseProjectFileByPath,
    invalidateProjectFileCache,
    normalizePathKey,
} = projectFile;

// ---------------------------------------------------------------------------
// 断言
// ---------------------------------------------------------------------------

let passed = 0;
let failed = 0;

function check(label, actual, expected) {
    const ok = JSON.stringify(actual) === JSON.stringify(expected);
    if (ok) {
        passed++;
        console.log(`  \u2713 ${label}`);
    } else {
        failed++;
        console.log(`  \u2717 ${label}\n      期望: ${JSON.stringify(expected)}\n      实际: ${JSON.stringify(actual)}`);
    }
}

function checkTrue(label, cond, detail = '') {
    if (cond) {
        passed++;
        console.log(`  \u2713 ${label}`);
    } else {
        failed++;
        console.log(`  \u2717 ${label} ${detail}`);
    }
}

const rel = p => path.relative(WORKSPACE, p).replace(/\\/g, '/');

// ---------------------------------------------------------------------------
// 用例
// ---------------------------------------------------------------------------

console.log(`\n工作区: ${WORKSPACE}\n`);

console.log('【1】扫描范围');
invalidateProjectFileCache();
const scanned = findAllProjectFiles(true);
const scannedRel = scanned.map(rel);

checkTrue('扫描到 4 个真实工程', ['alpha_anlogic/alpha.al', 'beta_xilinx/beta.xpr',
    'delta_xilinx/delta.xpr', 'nested/deep/gamma_anlogic/gamma.al'].every(r => scannedRel.includes(r)),
    `实际: ${JSON.stringify(scannedRel)}`);

check('厂商生成物目录被跳过', scannedRel.filter(r => /_Runs|\.gen|\.srcs|\.cache|\.Xil|netlist/.test(r)), []);

console.log('\n【2】.al 解析（安路）');
const alpha = parseProjectFileByPath(path.join(WORKSPACE, 'alpha_anlogic/alpha.al'));
check('工程类型', alpha.kind, 'al');
check('器件', alpha.device, 'PH1A90SEG325');
check('速度等级去掉负号', alpha.speed, '2');
check('设计顶层', alpha.topModuleSrc, 'alpha_top');
check('设计文件数（AutoExcluded 已剔除）', alpha.srcFiles.length, 4);
check('跨目录文件已解析为绝对路径', rel(alpha.srcFiles.find(f => f.path.includes('shared_util')).path), 'common/shared_util.v');
check('被排除的文件不在列表中', alpha.srcFiles.some(f => f.path.includes('alpha_excluded')), false);
check('设计源不含约束文件', alpha.srcFiles.some(f => /\.(adc|sdc|xdc)$/i.test(f.path)), false);
check('约束文件数（adc + sdc）', alpha.dataFiles.length, 2);
check('约束文件归类正确', alpha.dataFiles.map(f => rel(f.path)).sort(), ['alpha_anlogic/constr/alpha.sdc', 'alpha_anlogic/constr/pin.adc']);
check('IP 分类为空（alpha 未登记 IP）', alpha.ipFiles.length, 0);

console.log('\n【3】.xpr 解析（Xilinx）');
const beta = parseProjectFileByPath(path.join(WORKSPACE, 'beta_xilinx/beta.xpr'));
check('工程类型', beta.kind, 'xpr');
check('设计顶层', beta.topModuleSrc, 'beta_top');
check('设计文件数', beta.srcFiles.length, 5);
check('仿真顶层', beta.topModuleSim, 'tb_beta_top');
check('仿真文件数', beta.simFiles.length, 1);
check('约束文件数', beta.dataFiles.length, 1);
check('$PPRDIR 已展开', rel(beta.srcFiles[0].path), 'beta_xilinx/src/beta_top.v');
check('$PPRDIR/.. 已展开', rel(beta.srcFiles.find(f => f.path.includes('shared_util')).path), 'common/shared_util.v');
check('设计源不含约束与仿真', beta.srcFiles.some(f => /\.(xdc|adc|sdc)$/i.test(f.path) || /tb_/.test(f.path)), false);
checkTrue('BlockSrcs 归入 IP 分类', beta.ipFiles.length >= 1, `实际 ${beta.ipFiles.length}`);

console.log('\n【4】多工程列举与激活态');
let infos = getAllProjectFileInfos();
checkTrue('列举到多个工程', infos.length >= 4, `实际 ${infos.length}`);
check('默认激活第一个可解析工程', rel(getActiveProjectFile()), 'alpha_anlogic/alpha.al');
checkTrue('恰好一个工程处于激活态', infos.filter(i => i.active).length === 1,
    `实际 ${infos.filter(i => i.active).length}`);

console.log('\n【5】切换激活工程');
const betaPath = path.join(WORKSPACE, 'beta_xilinx/beta.xpr');
setActiveProjectFile(hdlPath.toSlash(betaPath)).then(() => {
    invalidateProjectFileCache();
    check('切换后激活工程生效', rel(getActiveProjectFile()), 'beta_xilinx/beta.xpr');
    infos = getAllProjectFileInfos();
    const actives = infos.filter(i => i.active);
    check('切换后仍只有一个激活工程', actives.length, 1);
    check('激活的是 beta', actives[0] && rel(actives[0].info.file), 'beta_xilinx/beta.xpr');

    console.log('\n【6】异常工程容错');
    const broken = parseProjectFileByPath(path.join(WORKSPACE, 'broken/broken.al'));
    checkTrue('截断的 .al 解析返回 undefined', broken === undefined);
    const brokenX = parseProjectFileByPath(path.join(WORKSPACE, 'broken/broken.xpr'));
    checkTrue('非 XML 的 .xpr 解析返回 undefined', brokenX === undefined);
    const empty = parseProjectFileByPath(path.join(WORKSPACE, 'noise/empty_lib.xpr'));
    checkTrue('空工程可解析', empty !== undefined);
    check('空工程文件数为 0', empty ? empty.srcFiles.length + empty.simFiles.length + empty.dataFiles.length + empty.ipFiles.length : -1, 0);
    checkTrue('损坏工程不影响其它工程', getAllProjectFileInfos().length >= 4);
    checkTrue('损坏工程不出现在工程列表中',
        !getAllProjectFileInfos().some(i => i.info.file.includes('broken')));

    console.log('\n【7】缓存一致性');
    const a1 = parseProjectFileByPath(path.join(WORKSPACE, 'alpha_anlogic/alpha.al'));
    const a2 = parseProjectFileByPath(path.join(WORKSPACE, 'alpha_anlogic/alpha.al'));
    checkTrue('同一文件两次解析为同一对象（命中缓存）', a1 === a2);
    invalidateProjectFileCache();
    const a3 = parseProjectFileByPath(path.join(WORKSPACE, 'alpha_anlogic/alpha.al'));
    checkTrue('缓存失效后重新解析（对象不同但内容一致）', a3 !== a1 && a3.srcFiles.length === a1.srcFiles.length);

    console.log(`\n${'='.repeat(50)}`);
    console.log(`通过 ${passed} 项，失败 ${failed} 项`);
    console.log(`${'='.repeat(50)}\n`);
    process.exit(failed > 0 ? 1 : 0);
});
