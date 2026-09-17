#!/usr/bin/env bash

set -euo pipefail

SCRIPT_DIR="$(CDPATH= cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
EXTENSION_ROOT="$(CDPATH= cd -- "$SCRIPT_DIR/.." && pwd)"
SERVER_ROOT="$(CDPATH= cd -- "$EXTENSION_ROOT/.." && pwd)"
DEFAULT_WORKSPACE="$SERVER_ROOT/tests/project/temp"
CONTROLLER_SOURCE="$SCRIPT_DIR/debug-launcher"
CONTROLLER_ID="codex.digital-ide-current-window-controller"
CONTROLLER_VERSION="1.0.0"
BUILD_ROOT="$SERVER_ROOT/target/digital-ide-debug-launcher"
REQUEST_ROOT="$HOME/.cache/digital-ide-current-window-controller"
BACKEND_PATH="$SERVER_ROOT/target/debug/digital-server"
VHDL_LIBRARY_PATH="$SERVER_ROOT/tests/vhdl/vhdl_libraries"

workspace="$DEFAULT_WORKSPACE"
controller_workspace="$SERVER_ROOT"
activation_file=""
netlist_module=""
build=true
timeout_seconds=60
request_path=""

usage() {
    cat <<EOF
Usage: $(basename "$0") [options]

Ask the current VS Code window to open Digital IDE in one Extension Development Host.

Options:
  --workspace PATH   Workspace to open (default: $DEFAULT_WORKSPACE)
  --controller PATH  Workspace open in the current controller window
                     (default: $SERVER_ROOT)
  --file PATH        HDL file to open; relative paths use the target workspace
  --netlist MODULE   Open MODULE in the netlist Webview after startup
  --no-build         Reuse the current WebUI, TypeScript output, and debug backends
  --timeout SEC      Startup verification timeout (default: 60)
  -h, --help         Show this help
EOF
}

fail() {
    printf 'error: %s\n' "$*" >&2
    exit 1
}

require_command() {
    command -v "$1" >/dev/null 2>&1 || fail "required command not found: $1"
}

supports_webui_build() {
    "$1" -e '
        const [major, minor] = process.versions.node.split(".").map(Number);
        process.exit((major === 20 && minor >= 19) ||
            (major === 22 && minor >= 12) || major > 22 ? 0 : 1);
    ' >/dev/null 2>&1
}

select_build_node() {
    supports_webui_build node && return 0

    local previous_version candidate
    local -a candidate_dirs
    previous_version="$(node --version 2>/dev/null || printf 'not installed')"
    IFS=: read -r -a candidate_dirs <<<"$PATH"
    candidate_dirs+=("$HOME/.local/bin" "${NVM_DIR:-$HOME/.nvm}"/versions/node/*/bin)
    for candidate in "${candidate_dirs[@]}"; do
        [[ -n "$candidate" ]] || candidate=.
        [[ -x "$candidate/node" && -x "$candidate/npm" ]] || continue
        if supports_webui_build "$candidate/node"; then
            # npm and its nested build scripts must resolve the same Node runtime.
            export PATH="$candidate:$PATH"
            hash -r
            printf 'Using Node.js %s from %s (previous: %s).\n' \
                "$(node --version)" "$candidate" "$previous_version"
            return 0
        fi
    done

    fail "WebUI builds require Node.js 20.19+ (20.x) or 22.12+; current: $previous_version. Install a supported Node.js version and add its bin directory to PATH."
}

cleanup() {
    if [[ -n "$request_path" ]]; then
        rm -f "$request_path"
    fi
}

trap cleanup EXIT

while (($# > 0)); do
    case "$1" in
        --workspace)
            (($# >= 2)) || fail "--workspace requires a path"
            workspace="$2"
            shift 2
            ;;
        --controller)
            (($# >= 2)) || fail "--controller requires a path"
            controller_workspace="$2"
            shift 2
            ;;
        --file)
            (($# >= 2)) || fail "--file requires a path"
            activation_file="$2"
            shift 2
            ;;
        --netlist)
            (($# >= 2)) || fail "--netlist requires a module name"
            netlist_module="$2"
            shift 2
            ;;
        --no-build)
            build=false
            shift
            ;;
        --timeout)
            (($# >= 2)) || fail "--timeout requires a number"
            timeout_seconds="$2"
            shift 2
            ;;
        -h|--help)
            usage
            exit 0
            ;;
        *)
            fail "unknown option: $1"
            ;;
    esac
done

[[ "$timeout_seconds" =~ ^[1-9][0-9]*$ ]] || fail "--timeout must be a positive integer"

require_command code
if $build; then
    select_build_node
fi
require_command node
require_command npm
require_command cargo
require_command zip
require_command sha256sum

workspace="$(realpath -e "$workspace")" || fail "workspace does not exist: $workspace"
controller_workspace="$(realpath -e "$controller_workspace")" || fail "controller workspace does not exist: $controller_workspace"
[[ -d "$workspace" ]] || fail "workspace is not a directory: $workspace"
[[ -d "$controller_workspace" ]] || fail "controller workspace is not a directory: $controller_workspace"
[[ -f "$workspace/.vscode/property.json" ]] || fail "workspace is missing .vscode/property.json: $workspace"
[[ -f "$VHDL_LIBRARY_PATH/std/standard.vhd" ]] \
    || fail "VHDL standard library is missing: $VHDL_LIBRARY_PATH/std/standard.vhd"
[[ -f "$VHDL_LIBRARY_PATH/ieee/std_logic_1164.vhdl" ]] \
    || fail "VHDL IEEE library is missing: $VHDL_LIBRARY_PATH/ieee/std_logic_1164.vhdl"

if [[ -n "$activation_file" ]]; then
    if [[ "$activation_file" != /* ]]; then
        activation_file="$workspace/$activation_file"
    fi
    activation_file="$(realpath -e "$activation_file")" || fail "activation file does not exist"
else
    activation_file="$(node "$SCRIPT_DIR/resolve-debug-activation.js" "$workspace")"
    if [[ -z "$activation_file" ]]; then
        printf 'No non-ignored project HDL file found; opening the workspace without an activation file.\n'
    fi
fi

mkdir -p "$BUILD_ROOT" "$REQUEST_ROOT"

if $build; then
    printf '[1/5] Building the Waveform and netlist WebUIs and extension...\n'
    if ! npm --prefix "$EXTENSION_ROOT" run build:waveform --silent >"$BUILD_ROOT/npm-waveform.log" 2>&1; then
        tail -n 80 "$BUILD_ROOT/npm-waveform.log" >&2
        fail "Waveform WebUI build failed"
    fi
    if ! npm --prefix "$EXTENSION_ROOT" run build:netlist --silent >"$BUILD_ROOT/npm-netlist.log" 2>&1; then
        tail -n 80 "$BUILD_ROOT/npm-netlist.log" >&2
        fail "netlist WebUI build failed"
    fi
    if ! npm --prefix "$EXTENSION_ROOT" run compile --silent >"$BUILD_ROOT/npm-compile.log" 2>&1; then
        tail -n 80 "$BUILD_ROOT/npm-compile.log" >&2
        fail "extension compilation failed"
    fi

    printf '[2/5] Building the debug backend...\n'
    if ! cargo build --quiet --manifest-path "$SERVER_ROOT/Cargo.toml" \
        --bin digital-server >"$BUILD_ROOT/cargo-build.log" 2>&1; then
        tail -n 120 "$BUILD_ROOT/cargo-build.log" >&2
        fail "digital-server build failed"
    fi
else
    printf '[1/5] Reusing existing build output (--no-build).\n'
fi

[[ -f "$EXTENSION_ROOT/out/extension.js" ]] || fail "compiled extension is missing: $EXTENSION_ROOT/out/extension.js"
[[ -x "$BACKEND_PATH" ]] || fail "debug backend is missing or not executable: $BACKEND_PATH"

controller_hash="$({
    sha256sum \
        "$CONTROLLER_SOURCE/[Content_Types].xml" \
        "$CONTROLLER_SOURCE/extension.vsixmanifest" \
        "$CONTROLLER_SOURCE/extension/package.json" \
        "$CONTROLLER_SOURCE/extension/extension.js"
} | sha256sum | awk '{print $1}')"
controller_hash_file="$BUILD_ROOT/current-window-controller.sha256"
controller_vsix="$BUILD_ROOT/digital-ide-current-window-controller-$CONTROLLER_VERSION.vsix"
installed_controller="$(code --list-extensions --show-versions 2>/dev/null | tr -d '\r' | grep -Fqx "$CONTROLLER_ID@$CONTROLLER_VERSION" && printf yes || true)"
recorded_hash="$(cat "$controller_hash_file" 2>/dev/null || true)"

printf '[3/5] Preparing the current-window debug controller...\n'
if [[ "$installed_controller" != yes || "$recorded_hash" != "$controller_hash" ]]; then
    temporary_zip="$BUILD_ROOT/controller-$$.zip"
    rm -f "$temporary_zip" "$controller_vsix"
    (
        cd "$CONTROLLER_SOURCE"
        zip -q -r "$temporary_zip" '[Content_Types].xml' extension.vsixmanifest extension
    )
    mv "$temporary_zip" "$controller_vsix"
    if ! code --install-extension "$controller_vsix" --force >"$BUILD_ROOT/controller-install.log" 2>&1; then
        tail -n 80 "$BUILD_ROOT/controller-install.log" >&2
        fail "VS Code current-window controller installation failed"
    fi
    printf '%s\n' "$controller_hash" >"$controller_hash_file"
fi

list_debug_hosts() {
    pgrep -u "$(id -u)" -f -- '--inspect-brk=.*bootstrap-fork --type=extensionHost' 2>/dev/null || true
}

list_digital_debug_hosts() {
    local pid
    while IFS= read -r pid; do
        [[ -n "$pid" ]] || continue
        if tr '\0' '\n' <"/proc/$pid/environ" 2>/dev/null \
            | grep -Fqx "DIGITAL_SERVER_PATH=$BACKEND_PATH"; then
            printf '%s\n' "$pid"
        fi
    done < <(list_debug_hosts)
}

list_regular_hosts() {
    local pid arguments
    while IFS= read -r pid; do
        [[ -n "$pid" ]] || continue
        arguments="$(tr '\0' ' ' <"/proc/$pid/cmdline" 2>/dev/null || true)"
        [[ "$arguments" == *'--inspect-brk='* ]] && continue
        printf '%s\n' "$pid"
    done < <(pgrep -u "$(id -u)" -f -- 'bootstrap-fork --type=extensionHost' 2>/dev/null || true)
}

list_workspace_backends() {
    local proc pid proc_exe proc_cwd
    for proc in /proc/[0-9]*; do
        pid="${proc#/proc/}"
        proc_exe="$(readlink "$proc/exe" 2>/dev/null || true)"
        [[ "$proc_exe" == "$BACKEND_PATH" ]] || continue
        proc_cwd="$(readlink "$proc/cwd" 2>/dev/null || true)"
        [[ "$proc_cwd" == "$workspace" ]] || continue
        printf '%s\n' "$pid"
    done
}

stop_process_list() {
    local label="$1" pids="$2" pid deadline remaining
    [[ -n "$pids" ]] || return 0
    printf 'Stopping the previous %s: %s\n' "$label" "$(tr '\n' ' ' <<<"$pids")"
    while IFS= read -r pid; do
        [[ -n "$pid" ]] || continue
        kill "$pid" 2>/dev/null || true
    done <<<"$pids"

    deadline=$((SECONDS + 10))
    while ((SECONDS < deadline)); do
        remaining=""
        while IFS= read -r pid; do
            [[ -n "$pid" ]] || continue
            if kill -0 "$pid" 2>/dev/null; then
                remaining+="$pid "
            fi
        done <<<"$pids"
        [[ -z "$remaining" ]] && return
        sleep 1
    done
    fail "previous $label did not stop within 10s: $remaining"
}

count_processes() {
    awk 'NF { count += 1 } END { print count + 0 }'
}

is_new_pid() {
    local pid="$1" previous="$2"
    ! grep -Fqx "$pid" <<<"$previous"
}

stop_process_list "Digital IDE Extension Development Host" "$(list_digital_debug_hosts)"
stop_process_list "Digital IDE workspace backend" "$(list_workspace_backends)"

before_debug_hosts="$(list_debug_hosts)"
before_regular_hosts="$(list_regular_hosts)"
before_backends="$(list_workspace_backends)"
[[ -n "$before_regular_hosts" ]] || fail "no running VS Code window is available as the debug controller"

session_id="$(date +%s)-$$"
request_path="$REQUEST_ROOT/request-$session_id.json"
status_path="$REQUEST_ROOT/status-$session_id.json"
SESSION_ID_VALUE="$session_id" \
CONTROLLER_WORKSPACE_VALUE="$controller_workspace" \
EXTENSION_PATH_VALUE="$EXTENSION_ROOT" \
WORKSPACE_PATH_VALUE="$workspace" \
ACTIVATION_FILE_VALUE="$activation_file" \
SERVER_PATH_VALUE="$BACKEND_PATH" \
VHDL_LIBRARY_PATH_VALUE="$VHDL_LIBRARY_PATH" \
REQUEST_PATH_VALUE="$request_path" \
STATUS_PATH_VALUE="$status_path" \
TIMEOUT_SECONDS_VALUE="$timeout_seconds" \
node <<'NODE'
const fs = require('fs');

const requestPath = process.env.REQUEST_PATH_VALUE;
const temporaryPath = `${requestPath}.tmp`;
const config = {
    sessionId: process.env.SESSION_ID_VALUE,
    controllerWorkspacePath: process.env.CONTROLLER_WORKSPACE_VALUE,
    extensionPath: process.env.EXTENSION_PATH_VALUE,
    workspacePath: process.env.WORKSPACE_PATH_VALUE,
    activationFile: process.env.ACTIVATION_FILE_VALUE,
    serverPath: process.env.SERVER_PATH_VALUE,
    vhdlLibraryPath: process.env.VHDL_LIBRARY_PATH_VALUE,
    statusPath: process.env.STATUS_PATH_VALUE,
    createdAt: Date.now(),
    expiresAt: Date.now() + Number(process.env.TIMEOUT_SECONDS_VALUE) * 1000,
};

fs.writeFileSync(temporaryPath, `${JSON.stringify(config, null, 2)}\n`, 'utf8');
fs.renameSync(temporaryPath, requestPath);
NODE

printf '[4/5] Asking the current VS Code window to start debugging...\n'
printf '  Controller workspace: %s\n' "$controller_workspace"
deadline=$((SECONDS + timeout_seconds))
debug_host_pid=""
while ((SECONDS < deadline)); do
    if [[ -f "$status_path" ]] && grep -Fq '"state": "error"' "$status_path"; then
        cat "$status_path" >&2
        fail "the current VS Code window rejected the debug request"
    fi
    while IFS= read -r pid; do
        [[ -n "$pid" ]] || continue
        if is_new_pid "$pid" "$before_debug_hosts"; then
            debug_host_pid="$pid"
            break 2
        fi
    done < <(list_debug_hosts)
    sleep 1
done

if [[ -z "$debug_host_pid" ]]; then
    [[ -f "$status_path" ]] && cat "$status_path" >&2
    printf 'Expected a VS Code window with this workspace open: %s\n' "$controller_workspace" >&2
    printf 'Use --controller PATH to select a different open workspace.\n' >&2
    fail "the current VS Code window did not consume the debug request within ${timeout_seconds}s"
fi

printf '[5/5] Waiting for the debug backend...\n'
deadline=$((SECONDS + timeout_seconds))
backend_pid=""
while ((SECONDS < deadline)); do
    while IFS= read -r pid; do
        [[ -n "$pid" ]] || continue
        if is_new_pid "$pid" "$before_backends"; then
            backend_pid="$pid"
            break 2
        fi
    done < <(list_workspace_backends)
    sleep 1
done

if [[ -z "$backend_pid" ]]; then
    printf 'Extension Development Host PID: %s\n' "$debug_host_pid" >&2
    [[ -f "$status_path" ]] && cat "$status_path" >&2
    printf 'Logs: %s\n' "$BUILD_ROOT" >&2
    fail "digital-server did not start within ${timeout_seconds}s"
fi

controller_pid="$(STATUS_PATH_VALUE="$status_path" node <<'NODE'
const fs = require('fs');
const status = JSON.parse(fs.readFileSync(process.env.STATUS_PATH_VALUE, 'utf8'));
process.stdout.write(String(status.controllerPid ?? ''));
NODE
)"
[[ -n "$controller_pid" ]] || fail "controller status did not record its extension-host PID"
grep -Fqx "$controller_pid" <<<"$before_regular_hosts" || fail "debug request was not handled by a pre-existing VS Code window"

new_regular_hosts=""
while IFS= read -r pid; do
    [[ -n "$pid" ]] || continue
    if is_new_pid "$pid" "$before_regular_hosts"; then
        new_regular_hosts+="$pid "
    fi
done < <(list_regular_hosts)
[[ -z "$new_regular_hosts" ]] || fail "an unexpected launcher Extension Host was created: $new_regular_hosts"

active_debug_hosts="$(list_digital_debug_hosts)"
active_backends="$(list_workspace_backends)"
[[ "$(count_processes <<<"$active_debug_hosts")" -eq 1 ]] \
    || fail "expected exactly one Digital IDE debug host, found: $active_debug_hosts"
[[ "$(count_processes <<<"$active_backends")" -eq 1 ]] \
    || fail "expected exactly one Digital IDE workspace backend, found: $active_backends"
grep -Fqx "$debug_host_pid" <<<"$active_debug_hosts" \
    || fail "verified debug host changed before startup completed"
grep -Fqx "$backend_pid" <<<"$active_backends" \
    || fail "verified backend changed before startup completed"

netlist_status=""
if [[ -n "$netlist_module" ]]; then
    extension_host_pid="$(ps -o ppid= -p "$backend_pid" | tr -d ' ')"
    extension_host_args="$(tr '\0' ' ' <"/proc/$extension_host_pid/cmdline")"
    if [[ "$extension_host_args" =~ --inspect-brk=([0-9]+) ]]; then
        inspector_port="${BASH_REMATCH[1]}"
    else
        fail "cannot locate the Extension Host inspector port"
    fi
    netlist_status="$(
        node "$SCRIPT_DIR/open-netlist-debug.js" \
            "$inspector_port" \
            "$workspace" \
            "$activation_file" \
            "$netlist_module"
    )"
fi

request_path=""
cat <<EOF

Digital IDE debug session is ready.
  Current VS Code controller PID: $controller_pid
  Extension host PID:            $debug_host_pid
  Backend PID:                   $backend_pid
  Workspace:                     $workspace
  Open file:                     $activation_file
  Netlist module:                ${netlist_module:-not requested}

Only one new window was opened: [Extension Development Host].
The current VS Code window owns the debug session and must remain open.
EOF
[[ -z "$netlist_status" ]] || printf '%s\n' "$netlist_status"
