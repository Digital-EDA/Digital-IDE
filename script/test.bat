@echo off

set production_folder=dist

@REM important static or config


if not exist %production_folder% (
    mkdir %production_folder%
)

echo vsce package
call vsce package
