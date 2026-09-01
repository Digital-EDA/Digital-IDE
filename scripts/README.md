Some scripts for config generation, batch processing etc.

Please run the all the scripts in the `extensionPath`.

command: scripts for `commands` in package.json


## Linux/Windows 通用安装包

在 Linux x86_64 主机执行：

```bash
./scripts/package-universal.sh
```

也可以从扩展目录执行：

```bash
npm run package:universal
```

脚本会自动准备固定版本的 LLVM 和 `cargo-xwin`、交叉编译 Windows 后端、安装锁定的
Node.js 依赖，同时构建 Linux release 后端及两种系统的 LSP 冒烟回归，最后只生成一个
不声明 `TargetPlatform` 的 VSIX。包内同时包含 Linux 后端、Windows 后端、Windows PDB
和崩溃监视器，扩展运行时按当前系统选择后端。首次运行需要联网，工具链缓存在后端的
`target/toolchains`，最终产物 `dist/fpga-support-<version>.vsix` 及 SHA-256 文件写入
`dist`。旧的 `package:linux-x64` 和 `package:win32-x64` 命令保留为同一通用入口的别名。

## Windows LSP 回归

在 Windows x64 上安装 Node.js 后，可对已打包的后端和 VS Code Extension Host
同时执行 SystemVerilog/VHDL 语言服务回归：

```powershell
npm run test:win32-lsp
```

该入口先直接验证 Windows `digital-server.exe` 的打开、第二次文档修订、补全、定义、
引用、hover、symbol、语义着色、inlay hint 和格式化，再通过 VS Code Extension Host
运行完整的 `SystemVerilog desktop LSP` 与 `VHDL desktop LSP` 套件。也可以用
`-Server D:\path\to\digital-server.exe` 指定待测后端。

Linux 打包机可通过 Docker/Wine 对同一个 PE 文件执行后端协议回归：

```bash
../../tests/windows/run-docker-wine-lsp-smoke.sh \
  ../../target/xwin-clang20/x86_64-pc-windows-msvc/release/digital-server.exe
```
