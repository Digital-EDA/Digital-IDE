# Xilinx ILA 调试案例

从已经打开本仓库的 VS Code 窗口执行：

```bash
tools/digital-server/tests/0.5.x/scripts/debug-xilinx-ila-demo.sh
```

脚本完成以下工作：

1. 在 `tools/digital-server/tests/project/xilinx/temp/prj/debugger/xilinx-ila-demo`
   生成带一个 ILA 和一个 VIO 的、hash 完整的 Vivado Debug Build 案例。
2. 启动一个以 Xilinx `temp` 为 workspace 的 Extension Development Host。
3. 自动打开 `Digital IDE: 模块树` 下的 `Debugger` 视图并载入
   `capture_bus` ILA 和 `control_bus` VIO。
4. 通过确定性的 Vivado Hardware Manager 夹具完成一次 64 点 ILA 采集，随后打开
   Waveform Webview 的 ILA Debug 交互界面。

该案例验证插件到 Vivado Hardware Manager 适配层、Debugger TreeView、ILA 采集发布和
Waveform Webview 的完整交互链路，不会访问真实开发板。实板使用时，Debug Build 由正常
HARD Build 生成，并由系统中的真实 `vivado`/`hw_server` 替代案例夹具。

复用已编译产物可缩短启动时间：

```bash
tools/digital-server/tests/0.5.x/scripts/debug-xilinx-ila-demo.sh --no-build
```
