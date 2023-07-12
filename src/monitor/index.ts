import * as chokidar from 'chokidar';
import { MainOutput, opeParam, ReportType } from '../global';
import { hdlExts } from '../global/lang';
import { PathSet } from '../global/util';
import { hdlPath } from '../hdlFs';

import * as Event from './event';

class HdlMonitor{
    private monitorConfig: chokidar.WatchOptions;
    public hdlMonitor?: chokidar.FSWatcher;
    public ppyMonitor?: chokidar.FSWatcher;

    constructor() {
        // public config for monitor
        this.monitorConfig = {
            persistent: true,
            usePolling: false,
            ignoreInitial: true
        };
    }

    public makeMonitor(paths: string | string[], config?: chokidar.WatchOptions): chokidar.FSWatcher {
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
        const hdlExtsGlob = `**/*.{${hdlExts.join(',')}}`;
        const prjInfo = opeParam.prjInfo;

        const monitorPathSet = new PathSet();
        monitorPathSet.checkAdd(prjInfo.hardwareSimPath);
        monitorPathSet.checkAdd(prjInfo.hardwareSrcPath);
        monitorPathSet.checkAdd(prjInfo.libCommonPath);
        monitorPathSet.checkAdd(prjInfo.libCustomPath);

        const monitorFoldersWithGlob = [];
        for (const folder of monitorPathSet.files) {
            const globPath = hdlPath.join(folder, hdlExtsGlob);
            monitorFoldersWithGlob.push(globPath);
        }
        MainOutput.report('Following folders are tracked: ');
        monitorPathSet.files.forEach(p => MainOutput.report(p));
                
        return this.makeMonitor(monitorFoldersWithGlob);
    }

    public close() {
        this.hdlMonitor?.close();
        this.ppyMonitor?.close();
    }

    public start() {
        // make monitor
        this.hdlMonitor = this.getHdlMonitor();
        this.ppyMonitor = this.getPpyMonitor();

        this.registerHdlMonitorListener();
        this.registerPpyMonitorListener();
    }

    public remakeHdlMonitor() {
        if (this.hdlMonitor) {
            this.hdlMonitor.close();
            this.hdlMonitor = this.getHdlMonitor();
            this.registerHdlMonitorListener();
        }
    }

    public registerHdlMonitorListener() {
        Event.hdlAction.listenAdd(this);
        Event.hdlAction.listenChange(this);
        Event.hdlAction.listenUnlink(this);

        // Event.hdlAction.listenAddDir(this);
        // Event.hdlAction.listenUnlinkDir(this);
    }

    public registerPpyMonitorListener() {
        Event.ppyAction.listenAdd(this);
        Event.ppyAction.listenChange(this);
        Event.ppyAction.listenUnlink(this);
    }
};

const hdlMonitor = new HdlMonitor();

export {
    hdlMonitor,
};

export type { HdlMonitor };