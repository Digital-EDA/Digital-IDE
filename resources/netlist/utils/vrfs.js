const fspath = require('path');
const fs = require('fs');

const os = require('os');
const exec  = require("child_process").execSync;

class Vrfs {
    constructor(module) {
        this.module = module;
    }

    /**
     * @descriptionCn 显示指定文件夹下的所有子目录, 并返回
     * @param {*} path 所要显示的文件夹的绝对路径 (省略对应root的\)
     * @returns 返回所有子目录
     */
    readdir(path) {
        let lists = this.module.FS.readdir(`/${path}`);
        console.log(lists);
        return lists;
    }

    /**
     * @descriptionCn 将本地路径挂载到虚拟文件系统下
     * @param {*} local   需要挂载的本地路径
     * @param {*} virtual 所要挂载到的虚拟文件系统的绝对路径 (省略对应root的/)
     */
    mount(local, virtual) {
        this.mkdir(virtual);
        this.module.FS.mount(this.module.NODEFS, { root: local }, `/${virtual}`);
    }

    /**
     * @descriptionCn 将当前系统根目录进行挂在到虚拟文件系统下
     */
    diskMount() {
        var aDrives = [];
        var result = null;
        var stdout = null;
        switch (os.platform().toLowerCase()) {
            case 'win32':
                result = exec('wmic logicaldisk get Caption,FreeSpace,Size,VolumeSerialNumber,Description  /format:list');
                stdout = result.toString();
                var aLines = stdout.split('\r\r\n');
                var bNew = false;
                var sCaption = '', sDescription = '', sFreeSpace = '', sSize = '', sVolume = '';
                // For each line get information
                // Format is Key=Value
                for(var i = 0; i < aLines.length; i++) {
                    if (aLines[i] !== '') {
                        var aTokens = aLines[i].split('=');
                        switch  (aTokens[0]) {
                            case 'Caption':											
                                sCaption = aTokens[1];
                                bNew = true;
                                break;
                            case 'Description':									
                                sDescription = aTokens[1];									
                                break;
                            case 'FreeSpace':
                                sFreeSpace = aTokens[1];
                                break;
                            case 'Size':
                                sSize = aTokens[1];
                                break;
                            case 'VolumeSerialNumber':
                                sVolume = aTokens[1];
                                break;
                        }
                    
                    } else {
                        // Empty line 
                        // If we get an empty line and bNew is true then we have retrieved
                        // all information for one drive, add to array and reset variables
                        if (bNew) {								
                            sSize = parseFloat(sSize);
                            if (isNaN(sSize)) {
                                sSize = 0;
                            }
                            sFreeSpace = parseFloat(sFreeSpace);
                            if (isNaN(sFreeSpace)) {
                                sFreeSpace = 0;
                            }
                            
                            var sUsed = (sSize - sFreeSpace);
                            var sPercent = '0%';
                            if (sSize !== '' && parseFloat(sSize) > 0) {
                                sPercent = Math.round((parseFloat(sUsed) / parseFloat(sSize)) * 100) + '%';
                            }
                            aDrives[aDrives.length] = {
                                filesystem:	sDescription,
                                blocks:		sSize,
                                used:		sUsed,
                                available:	sFreeSpace,
                                capacity:	sPercent,
                                mounted:	sCaption
                            };
                            bNew = false;
                            sCaption = ''; 
                            sDescription = ''; 
                            sFreeSpace = ''; 
                            sSize = ''; 
                            sVolume = '';
                        }
                    
                    }
                }
                for (var i = 0; i < aDrives.length; i++) {
                    let diskName = aDrives[i].mounted.toLowerCase();
                    console.log(diskName);
                    this.mount(diskName, diskName);
                }
            break;
            default:
                this.mount('/', 'host');
            break;
        }
    }

    /**
     * @state finish-test
     * @descriptionCn 虚拟文件系统下创建文件夹
     * @param {*} path 虚拟文件系统内部的绝对路径 (省略对应root的\)
     * 可越级创建，会自动生成父级文件夹
     */
    mkdir(path) {
        if (this.module.FS.findObject(`/${path}`) !== null) {
            return true;
        } else {
            let dirname = fspath.dirname(path);
            if (dirname === path) {
                this.module.FS.mkdir(`/${path}`);
                return true;
            }
            if (this.mkdir(dirname)) {
                this.module.FS.mkdir(`/${path}`);
            }
            return true;
        }
    }

    /**
     * @descriptionCn 删除虚拟文件系统下的文件夹
     * @param {*} path 虚拟文件系统内部的绝对路径 (省略对应root的\)
     * 可越级创建，会自动删除父级文件夹
     */
    rmdir(path) {
        let files = [];
        if (this.module.FS.findObject(`/${path}`) !== null) {
            files = this.module.FS.readdir(`/${path}`);
            for (let index = 2; index < files.length; index++) {
                const element = files[index];
                let curPath = fspath.join(`/${path}`, element).replace(/\\/g, "\/");
                let value = this.module.FS.isDir(this.module.FS.stat(curPath).mode);
                if (value) {
                    this.rmdir(curPath);
                } else {
                    this.module.FS.unlink(curPath);
                }
            }
            this.module.FS.rmdir(`/${path}`); //清除文件夹
        }
    }

    /**
     * @state finish-test
     * @descriptionCn 删除虚拟文件系统下的指定文件
     * @param {*} path 虚拟文件系统内部的绝对路径 (省略对应root的\)
     */
    rmfile(path) {
        this.module.FS.unlink(`/${path}`);
    }

    /**
     * @state finish-test
     * @descriptionCn 将本地路径下的文件写入虚拟文件系统
     * @param {*} src 文件的本地的绝对路径
     * @param {*} des 虚拟文件系统内部指定地址 (省略对应root的\)
     * 可越级创建，会自动生成父级文件夹
     */
    writeFileFormPath(src, des) {
        let desDir = fspath.dirname(des);
        let content = fs.readFileSync(src);
        if (this.module.FS.findObject(`/${desDir}`) !== null) {
            this.module.FS.writeFile(`/${des}`, content, { encoding: 'utf8' });
        } else {
            this.mkdir(`/${desDir}`);
            this.module.FS.writeFile(`/${des}`, content, { encoding: 'utf8' });
        }
    }

    /**
     * @state finish-test
     * @descriptionCn 将文件内容写入虚拟文件系统
     * @param {*} text 要写入的文件内容
     * @param {*} path 虚拟文件系统内部指定地址 (省略对应root的\)
     * 可越级创建，会自动生成父级文件夹
     */
    writeFileFormText(text, path) {
        let pathDir = fspath.dirname(path);
        if (this.module.FS.findObject(`/${pathDir}`) !== null) {
            this.module.FS.writeFile(`/${path}`, text, { encoding: 'utf8' });
        } else {
            this.mkdir(`/${pathDir}`);
            this.module.FS.writeFile(`/${path}`, text, { encoding: 'utf8' });
        }
    }

    /**
     * @state finish-test
     * @descriptionCn 从虚拟文件系统中读出文件到本地
     * @param {*} src 虚拟文件系统内部指定地址 (省略对应root的\)
     * @param {*} des 要写到的本地文件的绝对路径
     */
    readFileToPath(src, des) {
        if (this.module.FS.findObject(`/${src}`) !== null) {
            let content = this.module.FS.readFile(`/${src}`, { encoding: 'utf8' });
            fs.writeFileSync(des, content);
        } else {
            console.log(`ERROR: The ${src} is not at this virtual system.`);
        }
    }

    /**
     * @state finish-test
     * @descriptionCn 从虚拟文件系统中读出文件内容
     * @param {*} path 虚拟文件系统内部指定地址 (省略对应root的\)
     * @returns 读出文件的内容
     */
    readFileToText(path) {
        if (this.module.FS.findObject(`/${path}`) !== null) {
            let content = this.module.FS.readFile(`/${path}`, { encoding: 'utf8' });
            return content;
        } else {
            console.log(`ERROR: The ${path} is not at this virtual system.`);
        }
    }
}
module.exports = Vrfs;