# Change Log

All notable changes to the "digital-ide" extension will be documented in this file.

Check [Keep a Changelog](http://keepachangelog.com/) for recommendations on how to structure this file.

## [0.3.2] - 2023-11-01

Bug 修复
- 修复文档化input, output处注释无法正常显示到文档的 bug
- 修复 iverilog 仿真功能中，将重复的路径作为编译参数编译的 bug
- 修复 iverilog 仿真功能中，将 `include 加入或去除后，无法通过仿真编译的 bug （没有更新 instance 的 instModPathStatus 属性）

Feat
- 增加对 XDC，TCL 等脚本的 LSP 支持
- 增加 verilog, vhdl, xdc, tcl 等语言的图标
- 增加对于 vivado 的支持，用户可以通过添加 vivado 路径的方式（或者将 bin 文件夹添加到环境变量，默认路径为 C:\Xilinx\Vivado\2018.3\bin）来使用 vivado 的仿真和自动纠错
- 增加对于 modelsim 的支持，用户可以通过添加 modelsim 安装路径（或者将 bin 文件夹添加到环境变量，默认路径为 C:\modeltech64_10.4\win64）来使用 vivado 的仿真和自动纠错

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