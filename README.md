<center>
<img src="./images/icon.png"/>
</center>

# Digital IDE - version 0.3.3

![](https://img.shields.io/badge/version-0.3.3-blue)
![](https://img.shields.io/badge/engine-wasm-blue)
![](https://img.shields.io/badge/Verilog-support-green)
![](https://img.shields.io/badge/VHDL-support-green)
![](https://img.shields.io/badge/SystemVerilog-building-black)

- [Document (New)](https://sterben.nitcloud.cn/)
- [中文文档 (New)](https://sterben.nitcloud.cn/zh/)
- [Video](https://www.bilibili.com/video/BV1t14y1179V/?spm_id_from=333.999.0.0)


---

## Feature
- 增加对于 vhdl 的 全面支持（文件树、LSP等）
- 增加对 XDC，TCL 等脚本的 LSP 支持
- 增加 verilog, vhdl, xdc, tcl, vvp, vcd 等语言或生成文件的工作区图标
- 增加对于 vivado, modelsim, verilator 的支持，用户可以通过设置 `function.lsp.linter.vhdl.diagnostor`(设置 vhdl) 和 `function.lsp.linter.vlog.diagnostor`(设置 verilog) 来使用这些第三方工具的仿真和自动纠错。
- 增加对于 TCL, XDC, VVP 等脚本的 LSP 和 语法高亮 支持。

## Change
- 将插件的工作状态显示在 vscode 下侧的状态栏上，利于用户了解目前的设置状态
- 状态栏右下角现在可以看到目前选择的linter以及是否正常工作了
- 优化项目配置目录
- 优化自动补全的性能

## Bug 修复
- 修复文档化 input, output 处注释无法正常显示到文档的 bug
- 修复 iverilog 仿真功能中，将重复的路径作为编译参数编译的 bug
- 修复 iverilog 仿真功能中，将 <code>`include</code> 加入或去除后，无法通过仿真编译的 bug （没有更新 instance 的 instModPathStatus 属性）
- 修复其他已知 bug

---

## develop

```bash
python script/command/make_package.py
```

## library更新

library的更新不会随着Digital-IDE的git一起保存，是专门去拉取更新的，但是打包要一起打包进插件之中。