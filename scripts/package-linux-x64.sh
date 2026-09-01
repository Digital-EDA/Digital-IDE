#!/usr/bin/env bash
set -euo pipefail

script_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
if [[ "${DIDE_UNIVERSAL_CHILD:-0}" != "1" ]]; then
    exec bash "$script_dir/package-universal.sh"
fi
extension_root="$(cd "$script_dir/.." && pwd)"
server_root="$(cd "$extension_root/.." && pwd)"
dist_dir="$extension_root/dist"
server_resource="$extension_root/resources/server/linux/x64/digital-server"
windows_server_resource="$extension_root/resources/server/win32/x64/digital-server.exe"
windows_symbols_resource="$extension_root/resources/server/win32/x64/digital_server.pdb"
vhdl_library_source="$server_root/tests/vhdl/vhdl_libraries"
vhdl_library_resource="$extension_root/resources/vhdl_libraries"
primitive_source="$server_root/tests/factory/xilinx/primitive"
primitive_resource="$extension_root/resources/primitive/xilinx"
workspace="$extension_root/test-fixtures/workspace"

log() {
    printf '\n==> %s\n' "$*"
}

fail() {
    printf 'error: %s\n' "$*" >&2
    exit 1
}

require_command() {
    command -v "$1" >/dev/null 2>&1 || fail "required command not found: $1"
}

package_version() {
    node -p "require(process.argv[1]).version" "$extension_root/package.json"
}

cargo_version() {
    awk '
        /^\[package\]$/ { in_package = 1; next }
        /^\[/ { in_package = 0 }
        in_package && /^version = / {
            sub(/^version = "/, "")
            sub(/"$/, "")
            print
            exit
        }
    ' "$server_root/Cargo.toml"
}

validate_vsix() {
    local vsix="$1"
    local release_version="$2"
    local validation_dir
    validation_dir="$(mktemp -d "$extension_root/.vsix-validation.XXXXXX")"

    unzip -tqq "$vsix"
    unzip -q "$vsix" -d "$validation_dir"

    local packaged_server="$validation_dir/extension/resources/server/linux/x64/digital-server"
    local packaged_windows_server="$validation_dir/extension/resources/server/win32/x64/digital-server.exe"
    local packaged_windows_symbols="$validation_dir/extension/resources/server/win32/x64/digital_server.pdb"
    [[ -f "$validation_dir/extension/out/extension.js" ]] \
        || fail "VSIX does not contain extension/out/extension.js"
    [[ -f "$packaged_server" ]] || fail "VSIX does not contain the Linux x64 server"
    [[ -x "$packaged_server" ]] || fail "packaged Linux server is not executable"
    [[ -f "$packaged_windows_server" ]] || fail "VSIX does not contain the Windows x64 server"
    [[ -f "$packaged_windows_symbols" ]] || fail "VSIX does not contain Windows server symbols"
    [[ -f "$validation_dir/extension/resources/crash/windows-server-monitor.ps1" ]] \
        || fail "VSIX does not contain the Windows crash monitor"
    [[ ! -e "$validation_dir/extension/resources/server/linux/x64/wave-server" ]] \
        || fail "VSIX must not contain the standalone Wave Server"
    [[ -f "$validation_dir/extension/resources/kernel/yosys.wasm" ]] \
        || fail "VSIX does not contain resources/kernel/yosys.wasm"
    [[ -f "$validation_dir/extension/resources/kernel/place.wasm" ]] \
        || fail "VSIX does not contain the netlist placement backend"
    [[ -f "$validation_dir/extension/resources/kernel/route.wasm" ]] \
        || fail "VSIX does not contain the netlist routing backend"
    [[ -f "$validation_dir/extension/resources/waveform/index.html" ]] \
        || fail "VSIX does not contain the waveform WebUI publication"
    [[ -f "$validation_dir/extension/resources/waveform-build-manifest.json" ]] \
        || fail "VSIX does not contain the waveform publication manifest"
    [[ -f "$validation_dir/extension/resources/netlist/index.html" ]] \
        || fail "VSIX does not contain the netlist WebUI publication"
    [[ -f "$validation_dir/extension/resources/netlist-build-manifest.json" ]] \
        || fail "VSIX does not contain the netlist publication manifest"
    [[ -f "$validation_dir/extension/resources/vhdl_libraries/std/standard.vhd" ]] \
        || fail "VSIX does not contain the VHDL standard library"
    [[ -f "$validation_dir/extension/resources/vhdl_libraries/ieee/std_logic_1164.vhdl" ]] \
        || fail "VSIX does not contain the VHDL IEEE library"
    for catalog in primitive.bin primitive.json; do
        [[ -f "$validation_dir/extension/resources/primitive/xilinx/$catalog" ]] \
            || fail "VSIX does not contain the Xilinx $catalog catalog"
        [[ "$(sha256sum "$primitive_source/$catalog" | awk '{print $1}')" == \
           "$(sha256sum "$validation_dir/extension/resources/primitive/xilinx/$catalog" | awk '{print $1}')" ]] \
            || fail "packaged Xilinx $catalog differs from the server catalog"
    done
    if grep -Fq 'TargetPlatform=' "$validation_dir/extension.vsixmanifest"; then
        fail "universal VSIX must not declare a target platform"
    fi

    node - "$validation_dir/extension/package.json" "$release_version" <<'NODE'
const fs = require('fs');
const [manifestPath, expectedVersion] = process.argv.slice(2);
const manifest = JSON.parse(fs.readFileSync(manifestPath, 'utf8'));
if (manifest.version !== expectedVersion) {
    throw new Error(`VSIX version ${manifest.version} does not match ${expectedVersion}`);
}
if (manifest.icon !== 'images/icon.png') {
    throw new Error(`VSIX icon path ${manifest.icon} is not images/icon.png`);
}
NODE

    for icon in icon.png icon.svg; do
        [[ -f "$validation_dir/extension/images/$icon" ]] \
            || fail "VSIX does not contain images/$icon"
        [[ "$(sha256sum "$extension_root/images/$icon" | awk '{print $1}')" == \
           "$(sha256sum "$validation_dir/extension/images/$icon" | awk '{print $1}')" ]] \
            || fail "packaged images/$icon differs from the source icon"
    done

    file "$packaged_server" | grep -Eq 'ELF 64-bit.*x86-64' \
        || fail "packaged server is not a Linux x86-64 executable"
    file "$packaged_windows_server" | grep -Eq 'PE32\+ executable.*x86-64' \
        || fail "packaged Windows server is not a Windows x86-64 executable"
    [[ "$(sha256sum "$server_resource" | awk '{print $1}')" == \
       "$(sha256sum "$packaged_server" | awk '{print $1}')" ]] \
        || fail "packaged server hash does not match the built server"
    [[ "$(sha256sum "$windows_server_resource" | awk '{print $1}')" == \
       "$(sha256sum "$packaged_windows_server" | awk '{print $1}')" ]] \
        || fail "packaged Windows server hash does not match the built server"
    [[ "$(sha256sum "$windows_symbols_resource" | awk '{print $1}')" == \
       "$(sha256sum "$packaged_windows_symbols" | awk '{print $1}')" ]] \
        || fail "packaged Windows symbols hash does not match the built symbols"

    for asset in yosys.wasm place.wasm route.wasm; do
        [[ "$(sha256sum "$extension_root/resources/kernel/$asset" | awk '{print $1}')" == \
           "$(sha256sum "$validation_dir/extension/resources/kernel/$asset" | awk '{print $1}')" ]] \
            || fail "packaged $asset hash does not match the source asset"
    done

    rm -rf "$validation_dir"
}

[[ "$(uname -s)" == "Linux" ]] || fail "this packaging script must run on Linux"
[[ "$(uname -m)" == "x86_64" ]] || fail "this packaging script requires an x86_64 host"
for command in awk cargo file grep install mktemp node npm sha256sum unzip; do
    require_command "$command"
done

release_version="$(package_version)"
server_version="$(cargo_version)"
[[ -n "$release_version" ]] || fail "could not read the extension version"
[[ "$release_version" == "$server_version" ]] \
    || fail "version mismatch: extension=$release_version server=$server_version"

log "Building Digital Server $release_version for Linux x64"
cargo build \
    --release \
    --locked \
    --bin digital-server \
    --manifest-path "$server_root/Cargo.toml"

built_server="$server_root/target/release/digital-server"
[[ -f "$built_server" ]] || fail "Linux server was not produced: $built_server"
file "$built_server" | grep -Eq 'ELF 64-bit.*x86-64' \
    || fail "built server is not a Linux x86-64 executable"
mkdir -p "$(dirname "$server_resource")"
install -m 0755 "$built_server" "$server_resource"
rm -f "$extension_root/resources/server/linux/x64/wave-server"

log "Testing the Linux LSP backend"
node "$server_root/tests/windows/lsp-runtime-smoke.mjs" \
    --server "$built_server" \
    --workspace "$workspace" \
    --systemverilog-document "$workspace/src/sv/child.sv" \
    --vhdl-document "$workspace/src/vhdl/top.vhd" \
    --vhdl-library "$vhdl_library_source"

log "Installing locked extension dependencies"
(
    cd "$extension_root"
    npm ci --no-audit --no-fund
)

log "Publishing Xilinx primitive catalogs"
node "$extension_root/scripts/publish-primitives.js"
[[ -f "$primitive_resource/primitive.bin" && -f "$primitive_resource/primitive.json" ]] \
    || fail "Xilinx primitive catalogs were not published"

log "Publishing VHDL standard libraries"
rm -rf "$vhdl_library_resource"
mkdir -p "$vhdl_library_resource"
cp -a "$vhdl_library_source/." "$vhdl_library_resource/"

vsix="$dist_dir/fpga-support-$release_version.vsix"
sha_file="$vsix.sha256"
mkdir -p "$dist_dir"
rm -f "$dist_dir"/fpga-support-"$release_version"-linux-x64.vsix \
    "$dist_dir"/fpga-support-"$release_version"-linux-x64.vsix.sha256 \
    "$dist_dir"/fpga-support-"$release_version"-win32-x64.vsix \
    "$dist_dir"/fpga-support-"$release_version"-win32-x64.vsix.sha256 \
    "$vsix" "$sha_file"

log "Building and packaging Digital IDE $release_version"
(
    cd "$extension_root"
    npx --yes @vscode/vsce@3.6.2 package \
        --allow-star-activation \
        --out "$vsix"
)

log "Validating the VSIX"
validate_vsix "$vsix" "$release_version"
(
    cd "$dist_dir"
    sha256sum "$(basename "$vsix")" > "$(basename "$sha_file")"
)

printf '\nPackage: %s\n' "$vsix"
printf 'SHA-256: %s\n' "$(sha256sum "$vsix" | awk '{print $1}')"
