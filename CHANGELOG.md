# Change Log

All notable changes to the "digital-ide" extension will be documented in this file.

Check [Keep a Changelog](http://keepachangelog.com/) for recommendations on how to structure this file.

## [Unreleased]

- Initial release


## [2023.11.1]

Bug 修复
- 修复文档化input, output处注释无法正常显示到文档的 bug
- 修复 iverilog 仿真功能中，将重复的路径作为编译参数编译的 bug
- 修复 iverilog 仿真功能中，将 `include 加入或去除后，无法通过仿真编译的 bug （没有更新 instance 的 instModPathStatus 属性）
