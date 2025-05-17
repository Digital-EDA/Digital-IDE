import * as chokidar from 'chokidar';
import { MainOutput, opeParam, ReportType } from '../global';
import { PathSet } from '../global/util';

import { t } from '../i18n';
import { HdlAction } from './hdl';
import { PpyAction } from './propery';
import { IgnoreAction } from './ignore';

class HdlMonitor{
    private monitorConfig: chokidar.ChokidarOptions;
    public hdlMonitor?: chokidar.FSWatcher;
    public ppyMonitor?: chokidar.FSWatcher;
    public ignoreMonitor?: chokidar.FSWatcher;

    constructor() {
        // public config for monitor
        this.monitorConfig = {
            persistent: true,
            usePolling: false,
            ignoreInitial: true
        };
    }

    public makeMonitor(paths: string | string[], config?: chokidar.ChokidarOptions): chokidar.FSWatcher {
        if (!config) {
            config = this.monitorConfig;
        }
        return chokidar.watch(paths, config);
    }

    /**
     * @description get monitor for property.json
     */
    public getPpyMonitor() {
        const watcherPath = opeParam.propertyJsonPath;
        return this.makeMonitor(watcherPath);
    }

    /**
     * @description get monitor for HDLParam update
     */
    public getHdlMonitor() {
        const prjInfo = opeParam.prjInfo;
        const monitorPathSet = new PathSet();

        // 在输出中展示当前的监视路径
        monitorPathSet.checkAdd(opeParam.workspacePath);
        monitorPathSet.checkAdd(prjInfo.hardwareSimPath);
        monitorPathSet.checkAdd(prjInfo.hardwareSrcPath);
        monitorPathSet.checkAdd(prjInfo.libCommonPath);
        const reportString = ['', ...monitorPathSet.files].join('\n\t');
        MainOutput.report(t('info.launch.following-folder-tracked') + reportString, {
            level: ReportType.Launch
        });

        MainOutput.report(t('info.monitor.current-mode', opeParam.openMode));

        if (opeParam.openMode === 'file') {
            return this.makeMonitor([prjInfo.libCommonPath]);
        } else {
            // chokidar 4.0.0 开始不支持 glob，需要在每一个入口自己判断
            return this.makeMonitor([opeParam.workspacePath, prjInfo.libCommonPath]);
        }
    }

    public getIgnoreMonitor() {
        const watcherPath = opeParam.dideignorePath;
        return this.makeMonitor(watcherPath);
    }

    public close() {
        this.hdlMonitor?.close();
        this.ppyMonitor?.close();
        this.ignoreMonitor?.close();
    }

    public start() {
        // make monitor
        this.hdlMonitor = this.getHdlMonitor();
        this.ppyMonitor = this.getPpyMonitor();
        this.ignoreMonitor = this.getIgnoreMonitor();

        this.registerHdlMonitorListener();
        this.registerPpyMonitorListener();
        this.registerIgnoreMonitorListener();
    }

    public remakeHdlMonitor() {
        if (this.hdlMonitor) {
            this.hdlMonitor.close();
            this.hdlMonitor = this.getHdlMonitor();
            this.registerHdlMonitorListener();
        }
    }

    public remakePpyMonitor() {
        if (this.ppyMonitor) {
            this.ppyMonitor.close();
            this.ppyMonitor = this.getPpyMonitor();
            this.registerPpyMonitorListener();
        }
    }

    public remakeIgnoreMonitor() {
        if (this.ignoreMonitor) {
            this.ignoreMonitor.close();
            this.ignoreMonitor = this.getIgnoreMonitor();
            this.registerIgnoreMonitorListener();
        }
    }

    public registerHdlMonitorListener() {
        // 不需要实现 addDir 和 unlinkDir 事件
        // 因为删除文件夹时，下级各个文件会自动触发 add 和 unlink 事件
        // 因此，monitor 只需要实现对文件的监听即可
        
        const hdlAction = new HdlAction();
        hdlAction.listenAdd(this);
        hdlAction.listenChange(this);
        hdlAction.listenUnlink(this);
    }

    public registerPpyMonitorListener() {
        const ppyAction = new PpyAction();
        ppyAction.listenAdd(this);
        ppyAction.listenChange(this);
        ppyAction.listenUnlink(this);
    }

    public registerIgnoreMonitorListener() {
        const ignoreAction = new IgnoreAction();
        ignoreAction.listenAdd(this);
        ignoreAction.listenChange(this);
        ignoreAction.listenUnlink(this);
    }
};

const hdlMonitor = new HdlMonitor();

export {
    hdlMonitor,
};

export type { HdlMonitor };