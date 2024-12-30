# Change Log

All notable changes to the "digital-ide" extension will be documented in this file.

Check [Keep a Changelog](http://keepachangelog.com/) for recommendations on how to structure this file.

## [0.4.0]

- 新的 VCD 波形渲染器
- 新的 Netlist 渲染器
- 新的 LSP 后端

## [0.3.4] - 2024-08-28

Feature

wave 渲染器 https://nc-ai-lab.feishu.cn/wiki/K7gVwwU02iNMc8krIHucPwhqnff#share-NjuodrRQAoxEotxRicOc7BXDnOh



---

## [0.3.3] - 2024-02-05

Feature
- 重做了文档化功能，并且添加了参数和接口的 diagram 可视化的渲染模块
- 增加了波形显示器，支持以下特性
    - 完整的 vcd 支持，对于 IEEE VCD 标准完全支持。
    - 基于 wasm 的 数据解析 和基于 webgl2 的渲染，拥有接近原生的运行速度。
    - 主线程渲染和渲染数据的加载实现了调度隔离，再大的 vcd 也不会造成卡顿。
    - 支持用户自定义调整波形颜色，移动灵敏度等等。
    - 支持用户自定义搜索信号名称。

Bug 修复
- Verilog 参数例化位置错误
- [issue-51] 文档化的部分问题
- 点击 Refuse 会在用户工作区创建 json 文件


---
## [0.3.2] - 2023-11-01

Feature
- 增加对于 vhdl 的 全面支持（文件树、LSP等）
- 增加对 XDC，TCL 等脚本的 LSP 支持
- 增加 verilog, vhdl, xdc, tcl, vvp, vcd 等语言或生成文件的工作区图标
- 增加对于 vivado, modelsim, verilator 的支持，用户可以通过设置 `function.lsp.linter.vhdl.diagnostor`(设置 vhdl) 和 `function.lsp.linter.vlog.diagnostor`(设置 verilog) 来使用这些第三方工具的仿真和自动纠错。
- 增加对于 TCL, XDC, VVP 等脚本的 LSP 和 语法高亮 支持。

Change
- 将插件的工作状态显示在 vscode 下侧的状态栏上，利于用户了解目前的设置状态
- 状态栏右下角现在可以看到目前选择的linter以及是否正常工作了
- 优化项目配置目录
- 优化自动补全的性能

Bug 修复
- 修复文档化 input, output 处注释无法正常显示到文档的 bug
- 修复 iverilog 仿真功能中，将重复的路径作为编译参数编译的 bug
- 修复 iverilog 仿真功能中，将 <code>`include</code> 加入或去除后，无法通过仿真编译的 bug （没有更新 instance 的 instModPathStatus 属性）
- 修复其他已知 bug



## [0.1.23] - 2022-12-24
- Finish the css of documentation, see `./css/documentation.css` for detail.

## [0.1.23] - 2022-12-23
- Finish the function of documentation, webview display
- Finish the function of documentation, support export markdown and html

## [0.1.23] - 2022-12-22
- Rename partial tokens of verilog, make highlighting more colorful

## [0.1.23] - 2022-12-05
- Tree View can display the module that has not solved the dependence
- Finish the function of Instance and add icon for each solved module

## [0.1.23] - 2022-12-02
- Add unit test for most of logic

## [0.1.23] - 2022-12-01
- Finish reconstruction of HDLparam
- Finish the implementation of tree view

## [0.1.22] - 2022-01-20

- Fix lib files do not display in tree view

## [0.1.21] - 2022-01-20

- Fix issue [#26](https://github.com/Bestduan/Digital-IDE/issues/26)
- Rename as Digital-IDE
- Fix generate property.json file

## [0.1.20] - 2022-01-12

- Fix issue [#32](https://github.com/Bestduan/Digital-IDE/issues/32)

## [0.1.18] - 2021-09-12

- delete generate tb file 
- add function netlist show
- Fix issue [#25](https://github.com/Bestduan/fpga_support_plug/issues/25)
- Fix issue [#24](https://github.com/Bestduan/fpga_support_plug/issues/24)

## [0.1.17] - 2021-09-04

- Fix issue [#22](https://github.com/Bestduan/fpga_support_plug/issues/22)
- Fix issue [#21](https://github.com/Bestduan/fpga_support_plug/issues/21)
- Fix issue [#20](https://github.com/Bestduan/fpga_support_plug/issues/20)


## [0.1.16] - 2021-07-26

- Optimization of the kernel, fix High CPU usage
- Fix some other known bugs
- Add Formatter function

## [0.1.15] - 2021-05-02

- Fix some bugs and add instructions

## [0.1.12] - 2021-04-28

- Added simulation function, automatically pop up error message

## [0.1.10] - 2020-04-16

- Added simulation function, automatically pop up error message

## [0.1.8] - 2020-03-30

- Fixed the problem of repeatedly opening a new project and supported adding devices directly from the Makefile

## [0.1.6] - 2020-03-19

- Add support for IP design and bd design
- Add module jump (`Alt + F12` or `F12`)
- Change the startup shortcut key
- Fix some bugs to enhance robustness

## [0.1.4] - 2020-03-10

- Address the BUG existing in 0.1.3

## [0.1.2] - 2020-03-03

- Add Xilinx IP of Soc's cortexM3
- Provide an example for `m3_for_xilinx.bd`
- Resolve the file structure conversion problem

## [0.0.2] - 2020-02-28

- Added testbench / instance function

## [0.0.1] - 2020-02-15

- Initial Release