# One-command Digital IDE debug session

From the repository root, run:

```bash
tools/digital-server/tests/0.5.x/scripts/debug-digital-ide.sh
```

The script compiles the extension, builds the debug backend, installs or updates its small
remote controller, asks the current VS Code window to open the Xilinx temp workspace in an
Extension Development Host, and waits until the backend is running.

If an earlier Digital IDE debug host or backend for the same workspace is still running, the
script stops it before launching the replacement. It returns only after verifying exactly one
matching debug host and one matching backend. Use the window whose title contains
`[Extension Development Host]`. The original VS Code window owns the debug session and must
remain open while testing.

To reuse existing build output:

```bash
tools/digital-server/tests/0.5.x/scripts/debug-digital-ide.sh --no-build
```

To select another workspace, controller workspace, or initial HDL file:

```bash
tools/digital-server/tests/0.5.x/scripts/debug-digital-ide.sh \
  --controller /absolute/path/open/in/the/current/vscode \
  --workspace /absolute/path/to/workspace \
  --file relative/path/to/top.sv
```

To open an accepted backend netlist directly in the debug host, add the module name:

```bash
tools/digital-server/tests/0.5.x/scripts/debug-digital-ide.sh \
  --workspace /absolute/path/to/workspace \
  --file relative/path/to/top.sv \
  --netlist top
```

Generated controller packages and logs are written below
`tools/digital-server/target/digital-ide-debug-launcher`.
