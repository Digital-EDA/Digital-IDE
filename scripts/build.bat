@echo off
cls
echo [10%] compile typescript
call tsc -p ./ --outDir out-js

echo [20%] webpack 
call webpack --mode production

echo collect static resources
mkdir

echo [30%] remove out-js
if exist out-js (
    rmdir /s /q out-js
)
echo [30%] remove out
if exist out (
    rmdir /s /q out
)

echo [100%] finish build :D