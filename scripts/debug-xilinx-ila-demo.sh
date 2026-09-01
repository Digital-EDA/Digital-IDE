#!/usr/bin/env bash

set -euo pipefail

SCRIPT_DIR="$(CDPATH= cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
SERVER_ROOT="$(CDPATH= cd -- "$SCRIPT_DIR/../../.." && pwd)"
DEFAULT_WORKSPACE="$SERVER_ROOT/tests/project/xilinx/temp"
DEMO_ROOT="$SCRIPT_DIR/xilinx-ila-demo"

workspace="$DEFAULT_WORKSPACE"
forwarded=()

while (($# > 0)); do
    case "$1" in
        --workspace)
            (($# >= 2)) || {
                printf 'error: --workspace requires a path\n' >&2
                exit 1
            }
            workspace="$2"
            shift 2
            ;;
        *)
            forwarded+=("$1")
            shift
            ;;
    esac
done

workspace="$(realpath -e "$workspace")"
node "$DEMO_ROOT/prepare.js" "$workspace"

"$SCRIPT_DIR/debug-digital-ide.sh" \
    --workspace "$workspace" \
    --file user/src/Registers.v \
    "${forwarded[@]}"

backend_path="$SERVER_ROOT/target/debug/digital-server"
backend_pid=""
for proc in /proc/[0-9]*; do
    [[ "$(readlink "$proc/exe" 2>/dev/null || true)" == "$backend_path" ]] || continue
    [[ "$(readlink "$proc/cwd" 2>/dev/null || true)" == "$workspace" ]] || continue
    backend_pid="${proc#/proc/}"
    break
done
[[ -n "$backend_pid" ]] || {
    printf 'error: cannot locate the Xilinx demo backend after startup\n' >&2
    exit 1
}

extension_host_pid="$(ps -o ppid= -p "$backend_pid" | tr -d ' ')"
extension_host_args="$(tr '\0' ' ' <"/proc/$extension_host_pid/cmdline")"
if [[ "$extension_host_args" =~ --inspect-brk=([0-9]+) ]]; then
    inspector_port="${BASH_REMATCH[1]}"
else
    printf 'error: cannot locate the Extension Host inspector port\n' >&2
    exit 1
fi

node "$DEMO_ROOT/open.js" "$inspector_port" "$workspace"
