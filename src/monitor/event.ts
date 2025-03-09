import * as chokidar from 'chokidar';
import { AbsPath, MainOutput, opeParam, PrjInfoDefaults, RelPath, ReportType } from '../global';
import type { HdlMonitor } from './index';

export enum Event {
    Add = 'add',                 // emit when add file
    AddDir = 'addDir',           // emit when add folder
    Unlink = 'unlink',           // emit when delete file
    UnlinkDir = 'unlinkDir',     // emit when delete folder
    Change = 'change',           // emit when file changed
    Move = 'move',
    All = 'all',                 // all the change above
    Ready = 'ready',
    Raw = 'raw',
    Error = 'error'
};


export abstract class BaseAction {
    public listenChange(m: HdlMonitor) {
        const fSWatcher = this.selectFSWatcher(m);
        if (!fSWatcher) {
            MainOutput.report("FSWatcher hasn't been made!", {
                level: ReportType.Error
            });
            return;
        }
        fSWatcher.on(Event.Change, path => this.change(path, m));
    }

    public listenAdd(m: HdlMonitor) {
        const fSWatcher = this.selectFSWatcher(m);
        if (!fSWatcher) {
            MainOutput.report("FSWatcher hasn't been made!", {
                level: ReportType.Error
            });
            return;
        }
        fSWatcher.on(Event.Add, path => this.add(path, m));
    }

    public listenUnlink(m: HdlMonitor) {
        const fSWatcher = this.selectFSWatcher(m);
        if (!fSWatcher) {
            MainOutput.report("FSWatcher hasn't been made!", {
                level: ReportType.Error
            });
            return;
        }
        fSWatcher.on(Event.Unlink, path => this.unlink(path, m));
    }

    abstract selectFSWatcher(m: HdlMonitor): chokidar.FSWatcher | undefined;
    abstract change(path: AbsPath, m: HdlMonitor): Promise<void>;
    abstract add(path: AbsPath, m: HdlMonitor): Promise<void>;
    abstract unlink(path: AbsPath, m: HdlMonitor): Promise<void>;
}
