# Copilot instructions for Digital-IDE

## TL;DR ✅
- Extension (TypeScript) is in `src/` → compiled via `tsc` into `out/` or `out-js/` for packaging.
- A Rust-based language server (LSP) runs as a separate binary (prebuilt or built from the Rust repo). The extension launches it as an external process.
- Common dev commands: `npm install`, `npm run watch` (dev), `npm run compile`, `npm run vscode:prepublish` (webpack), `python scripts/command/make_package.py` (packaging).
- Extension only activates for workspaces that contain `.vscode/property.json` (see `resources/property/property-schema.json`).

---

## Big picture (architecture) 🔧
- Client: vscode extension written in TypeScript under `src/` (entry: `src/extension.ts`). It registers commands, webviews and launches the LSP client (`vscode-languageclient`).
- Server: external Rust LSP binary (repo: `digital-lsp-server` / `digital-server`), invoked by `src/server/server.ts` via an `Executable` (see hard-coded path in `server.ts`).
- Communication: the extension uses `LanguageClient` to talk LSP with the Rust server and also listens for custom notifications (e.g. `custom/hdlParamsUpdated`).

---

## Key files and places to look 📁
- `src/extension.ts` — extension activation and progress UI.
- `src/server/server.ts` — language client config and server launch (update path for local dev).
- `package.json` — activation event (`workspaceContains:.vscode/property.json`), commands, settings (external tool paths), scripts.
- `scripts/command/make_package.py` — packaging pipeline; uses `tsc` (out-js), `webpack`, `vsce` and post-processes the `.vsix`.
- `scripts/command/pull-digital-lsp.py` — convenience script to fetch prebuilt LSP binaries for multiple platforms.
- `resources/property/property-schema.json` — canonical `property.json` schema (project config).
- `src/global/outputs.ts` — logging conventions (use `MainOutput.report(...)` and output channels).

---

## Developer workflows & commands 🛠️
- Install deps: `npm install` and (for packaging) `npm i -g webpack-cli vsce`.
- Build for development: `npm run watch` (fast feedback via `tsc -w`).
- Full compile: `npm run compile`.
- Lint: `npm run lint` (ESLint on `src/`).
- Tests: `npm run pretest` runs compile + lint; `npm run test` runs `out/test/runTest.js` (VS Code test harness).
- Packaging: `python scripts/command/make_package.py` (requires Python dependencies such as `colorama`) — this creates and modifies a `.vsix` to include webview assets.

---

## Project-specific conventions & gotchas ⚠️
- Activation is conditional: the extension won't start unless `.vscode/property.json` exists in the workspace. To test features, create a minimal `property.json` that validates against `resources/property/property-schema.json`.
- LSP binary path is hard-coded in `src/server/server.ts`. For local dev either:
  - Build the Rust server and update the `command:` path in `server.ts` to the binary, or
  - Use `scripts/command/pull-digital-lsp.py` to download prebuilt binaries and use them.
- Packaging modifies the produced `.vsix` to inject `out-js` and static `resources/*` for webviews — simply running `vsce package` is not sufficient.
- Several features require external EDA tools; the extension exposes many `digital-ide.prj.*` settings (e.g. `prj.vivado.install.path`, `prj.modelsim.install.path`, `prj.verilator.install.path`) which must be set for those integrations to work.

---

## Examples of observable patterns to follow 💡
- Logging: use `MainOutput.report(message, { level: ReportType.Run })` to write to the extension output channel and optionally show notifications.
- LSP notifications: register `client.onNotification("custom/hdlParamsUpdated", payload => ...)` to receive server-driven updates.
- Internationalization: use `src/i18n/t(...)` and `package.nls.*.json` bundles for messages.

---

## When you need to change behavior or debug 🔍
- Start with `npm run watch` and attach the Extension Development host (F5 in VS Code) to iterate quickly.
- If the server isn’t running, check the hard-coded path in `src/server/server.ts` and either point it to a local build or use the pull script.
- Look at the `Digital-IDE` output channel (created by `src/global/outputs.ts`) and the `Digital-IDE Linter` / `Yosys` channels for task-specific logs.

---

If any of the above is unclear or you want me to add short examples (e.g., a minimal `property.json`, a recommended debug launch.json for running a local LSP build), tell me which piece to expand and I’ll iterate. 🎯
