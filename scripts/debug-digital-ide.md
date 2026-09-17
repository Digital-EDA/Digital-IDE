# One-command Digital IDE debug session

From the repository root, run:

```bash
./extension/scripts/debug-digital-ide.sh
```

The script compiles the extension, builds the debug backend, installs or updates its small
remote controller, asks the current VS Code window to open `tests/project/temp` in an
Extension Development Host, and waits until the backend is running.

The controller window must have this repository root open as a workspace folder. If the
current VS Code window has a different folder open, pass that folder with `--controller`.

If an earlier Digital IDE debug host or backend for the same workspace is still running, the
script stops it before launching the replacement. It returns only after verifying exactly one
matching debug host and one matching backend. Use the window whose title contains
`[Extension Development Host]`. The original VS Code window owns the debug session and must
remain open while testing.

To reuse existing build output:

```bash
./extension/scripts/debug-digital-ide.sh --no-build
```

To select another workspace, controller workspace, or initial HDL file:

```bash
./extension/scripts/debug-digital-ide.sh \
  --controller /absolute/path/open/in/the/current/vscode \
  --workspace /absolute/path/to/workspace \
  --file relative/path/to/top.sv
```

To open an accepted backend netlist directly in the debug host, add the module name:

```bash
./extension/scripts/debug-digital-ide.sh \
  --workspace /absolute/path/to/workspace \
  --file relative/path/to/top.sv \
  --netlist top
```

Generated controller packages and logs are written below
`target/digital-ide-debug-launcher`.

## Missing icons in Remote SSH

If the activity-bar and tree icons are blank, check the development window's
`Developer: Toggle Developer Tools` console. Errors such as
`vscode-managed-remote-resource://window:.../images/svg/...: net::ERR_FAILED`
can indicate a failure in VS Code's managed remote resource transport, even when
the SVG files exist and the extension can read them.

For this failure, set the following in the **local VS Code user settings** on the
SSH client, then reopen the remote development window:

```json
"remote.SSH.useExecServer": false
```

This uses the regular SSH/WebSocket connection instead of the managed connection.
It applies to Remote SSH connections from that client. No icon replacement or
WebUI rebuild is needed; `./extension/scripts/debug-digital-ide.sh --no-build`
can reopen the development window with the existing build output.
