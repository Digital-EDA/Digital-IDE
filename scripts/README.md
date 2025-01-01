Some scripts for config generation, batch processing etc.

Please run the all the scripts in the `extensionPath`.

command: scripts for `commands` in package.json


## 一键打包

如果初次运行，需要先安装一下依赖项：

```bash
$ npm install webpack-cli -g
$ npm install vsce -g
```

```bash
$ python script/command/make_package.py
```