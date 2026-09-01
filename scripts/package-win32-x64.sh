#!/usr/bin/env bash
set -euo pipefail

target="x86_64-pc-windows-msvc"
platform="win32-x64"
script_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
if [[ "${DIDE_UNIVERSAL_CHILD:-0}" != "1" ]]; then
    exec bash "$script_dir/package-universal.sh"
fi
extension_root="$(cd "$script_dir/.." && pwd)"
server_root="$(cd "$extension_root/.." && pwd)"
dist_dir="$extension_root/dist"
server_resource="$extension_root/resources/server/win32/x64/digital-server.exe"
server_symbols_resource="$extension_root/resources/server/win32/x64/digital_server.pdb"
vhdl_library_source="$server_root/tests/vhdl/vhdl_libraries"
vhdl_library_resource="$extension_root/resources/vhdl_libraries"
primitive_source="$server_root/tests/factory/xilinx/primitive"
primitive_resource="$extension_root/resources/primitive/xilinx"
parser_fingerprint_script="$server_root/sv-parser/scripts/windows-prebuilt-source-sha256.sh"

llvm_version="20.1.8"
llvm_deb_version="20.1.8~++20250708082409+6fb913d3e2ec-1~exp1~20250708202428.132"
llvm_base_url="https://apt.llvm.org/jammy/pool/main/l/llvm-toolchain-20"
llvm_root="$server_root/target/toolchains/llvm-$llvm_version"
llvm_downloads="$llvm_root/downloads"
llvm_sysroot="$llvm_root/root"
llvm_bin="$llvm_sysroot/usr/lib/llvm-20/bin"
llvm_lib="$llvm_sysroot/usr/lib/x86_64-linux-gnu"

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

repair_cargo_xwin_clang_link() {
    # cargo-xwin 0.23.0 checks a cached clang-cl link with Path::exists().
    # A dangling link left by a moved checkout therefore survives that check,
    # and the subsequent symlink creation fails with EEXIST. Remove only the
    # cache-managed link when it does not resolve to this pinned toolchain.
    local cache_dir="${XWIN_CACHE_DIR:-${XDG_CACHE_HOME:-$HOME/.cache}/cargo-xwin}"
    local clang_cl_link="$cache_dir/clang-cl"
    [[ -L "$clang_cl_link" || -e "$clang_cl_link" ]] || return 0

    local resolved=""
    if [[ -L "$clang_cl_link" ]]; then
        resolved="$(readlink -f "$clang_cl_link" 2>/dev/null || true)"
    fi
    if [[ "$resolved" != "$llvm_bin/clang" ]]; then
        log "Removing stale cargo-xwin clang-cl link"
        rm -f "$clang_cl_link"
    fi
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

download_deb() {
    local package="$1"
    local expected_sha="$2"
    local output="$llvm_downloads/$package.deb"
    local partial="$output.part"
    local url="$llvm_base_url/${package}_${llvm_deb_version}_amd64.deb"

    if [[ -f "$output" ]] && printf '%s  %s\n' "$expected_sha" "$output" | sha256sum -c - >/dev/null 2>&1; then
        return
    fi

    log "Downloading $package for LLVM $llvm_version"
    rm -f "$partial"
    curl --fail --location --retry 3 --output "$partial" "$url"
    printf '%s  %s\n' "$expected_sha" "$partial" | sha256sum -c - >/dev/null
    mv "$partial" "$output"
}

prepare_llvm() {
    local marker="$llvm_root/.ready"
    if [[ -x "$llvm_bin/clang" && -x "$llvm_bin/llvm-lib" && -x "$llvm_bin/lld-link" ]] \
        && [[ -f "$marker" ]] && [[ "$(<"$marker")" == "$llvm_version" ]]; then
        return
    fi

    mkdir -p "$llvm_downloads"
    download_deb clang-20 51bdb50d21a3ef8589afc777f94d7c24331ee4d646e13dcff7b1dbad00113dc4
    download_deb libclang-common-20-dev 5ee802ea28796d838714ecfcb0d42a64e88a313eb364fe408a7d3857e6157327
    download_deb libclang-cpp20 d7e30ff245dee201f2ad974e98a626685183743afe36a2eaba41670c47dc013a
    download_deb libllvm20 115548ed7c4d2fc69eebdd18f361a5edc1bd0bb37777792554bfa4675ba51bd6
    download_deb llvm-20 cc8fdb2bd8bb7b1828911d3160e3c7f3f04f604e17f193d8c0abfd55625f3a19
    download_deb lld-20 ecad131aabee8b1e76affc788e363bf6e58a4e7584b5af68ee1b926960c2fd21

    log "Extracting the pinned LLVM toolchain"
    rm -rf "$llvm_sysroot"
    mkdir -p "$llvm_sysroot"
    for package in clang-20 libclang-common-20-dev libclang-cpp20 libllvm20 llvm-20 lld-20; do
        dpkg-deb -x "$llvm_downloads/$package.deb" "$llvm_sysroot"
    done
    printf '%s\n' "$llvm_version" > "$marker"
}

validate_vsix() {
    local vsix="$1"
    local release_version="$2"
    local validation_dir
    validation_dir="$(mktemp -d "$extension_root/.vsix-validation.XXXXXX")"
    trap 'rm -rf "$validation_dir"' EXIT

    unzip -tqq "$vsix"
    unzip -q "$vsix" -d "$validation_dir"

    [[ -f "$validation_dir/extension/out/extension.js" ]] \
        || fail "VSIX does not contain extension/out/extension.js"
    [[ -f "$validation_dir/extension/resources/kernel/yosys.wasm" ]] \
        || fail "VSIX does not contain resources/kernel/yosys.wasm"
    [[ -f "$validation_dir/extension/resources/server/win32/x64/digital-server.exe" ]] \
        || fail "VSIX does not contain the Windows server"
    [[ -f "$validation_dir/extension/resources/server/win32/x64/digital_server.pdb" ]] \
        || fail "VSIX does not contain the Windows server symbols"
    [[ -f "$validation_dir/extension/resources/crash/windows-server-monitor.ps1" ]] \
        || fail "VSIX does not contain the Windows crash monitor"
    [[ ! -e "$validation_dir/extension/resources/server/win32/x64/wave-server.exe" ]] \
        || fail "VSIX must not contain the standalone Wave Server"
    [[ -f "$validation_dir/extension/resources/waveform/index.html" ]] \
        || fail "VSIX does not contain the waveform WebUI publication"
    [[ -f "$validation_dir/extension/resources/waveform-build-manifest.json" ]] \
        || fail "VSIX does not contain the waveform publication manifest"
    [[ -f "$validation_dir/extension/resources/netlist/index.html" ]] \
        || fail "VSIX does not contain the netlist WebUI publication"
    [[ -f "$validation_dir/extension/resources/netlist-build-manifest.json" ]] \
        || fail "VSIX does not contain the netlist publication manifest"
    [[ -f "$validation_dir/extension/resources/kernel/place.wasm" ]] \
        || fail "VSIX does not contain the netlist placement backend"
    [[ -f "$validation_dir/extension/resources/kernel/route.wasm" ]] \
        || fail "VSIX does not contain the netlist routing backend"
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
    grep -Fq 'TargetPlatform="win32-x64"' "$validation_dir/extension.vsixmanifest" \
        || fail "VSIX target platform is not win32-x64"

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

    file "$validation_dir/extension/resources/server/win32/x64/digital-server.exe" \
        | grep -Eq 'PE32\+ executable.*x86-64' \
        || fail "packaged server is not a Windows x86-64 executable"
    [[ "$(sha256sum "$server_resource" | awk '{print $1}')" == \
       "$(sha256sum "$validation_dir/extension/resources/server/win32/x64/digital-server.exe" | awk '{print $1}')" ]] \
        || fail "packaged server hash does not match the built server"
    [[ "$(sha256sum "$server_symbols_resource" | awk '{print $1}')" == \
       "$(sha256sum "$validation_dir/extension/resources/server/win32/x64/digital_server.pdb" | awk '{print $1}')" ]] \
        || fail "packaged server symbols hash does not match the built symbols"
    node - \
        "$extension_root/resources/waveform" \
        "$validation_dir/extension/resources/waveform" \
        "$extension_root/resources/waveform-build-manifest.json" \
        "$validation_dir/extension/resources/waveform-build-manifest.json" <<'NODE'
const crypto = require('crypto');
const fs = require('fs');
const path = require('path');
const [sourceRoot, packagedRoot, sourceManifest, packagedManifest] = process.argv.slice(2);

function filesBelow(root) {
    const files = [];
    const pending = [''];
    while (pending.length > 0) {
        const relative = pending.pop();
        for (const entry of fs.readdirSync(path.join(root, relative), { withFileTypes: true })) {
            const child = path.join(relative, entry.name);
            if (entry.isDirectory()) pending.push(child);
            else if (entry.isFile()) files.push(child.split(path.sep).join('/'));
        }
    }
    return files.sort();
}

function digest(root, files) {
    const hash = crypto.createHash('sha256');
    for (const relative of files) {
        hash.update(relative, 'utf8');
        hash.update('\0');
        hash.update(fs.readFileSync(path.join(root, relative)));
        hash.update('\0');
    }
    return hash.digest('hex');
}

const sourceFiles = filesBelow(sourceRoot);
const packagedFiles = filesBelow(packagedRoot);
const manifest = JSON.parse(fs.readFileSync(packagedManifest, 'utf8'));
if (JSON.stringify(sourceFiles) !== JSON.stringify(packagedFiles)
    || digest(sourceRoot, sourceFiles) !== digest(packagedRoot, packagedFiles)
    || digest(packagedRoot, packagedFiles) !== manifest.distSha256) {
    throw new Error('packaged waveform resources are not a byte-identical one-way publication');
}
if (!fs.readFileSync(sourceManifest).equals(fs.readFileSync(packagedManifest))) {
    throw new Error('packaged waveform publication manifest differs from the build manifest');
}
if (packagedFiles.some(file => /(^|\/)(src|tests)(\/|$)|\.(?:ts|tsx|vue)$/.test(file))) {
    throw new Error('packaged waveform publication contains development source');
}
NODE
    node - \
        "$extension_root/resources/netlist" \
        "$validation_dir/extension/resources/netlist" \
        "$extension_root/resources/netlist-build-manifest.json" \
        "$validation_dir/extension/resources/netlist-build-manifest.json" <<'NODE'
const crypto = require('crypto');
const fs = require('fs');
const path = require('path');
const [sourceRoot, packagedRoot, sourceManifest, packagedManifest] = process.argv.slice(2);

function filesBelow(root) {
    const files = [];
    const pending = [''];
    while (pending.length > 0) {
        const relative = pending.pop();
        for (const entry of fs.readdirSync(path.join(root, relative), { withFileTypes: true })) {
            const child = path.join(relative, entry.name);
            if (entry.isDirectory()) pending.push(child);
            else if (entry.isFile()) files.push(child.split(path.sep).join('/'));
        }
    }
    return files.sort();
}

function digest(root, files) {
    const hash = crypto.createHash('sha256');
    for (const relative of files) {
        hash.update(relative, 'utf8');
        hash.update('\0');
        hash.update(fs.readFileSync(path.join(root, relative)));
        hash.update('\0');
    }
    return hash.digest('hex');
}

const sourceFiles = filesBelow(sourceRoot);
const packagedFiles = filesBelow(packagedRoot);
const manifest = JSON.parse(fs.readFileSync(packagedManifest, 'utf8'));
if (JSON.stringify(sourceFiles) !== JSON.stringify(packagedFiles)
    || digest(sourceRoot, sourceFiles) !== digest(packagedRoot, packagedFiles)
    || digest(packagedRoot, packagedFiles) !== manifest.distSha256) {
    throw new Error('packaged netlist resources are not a byte-identical one-way publication');
}
if (!fs.readFileSync(sourceManifest).equals(fs.readFileSync(packagedManifest))) {
    throw new Error('packaged netlist publication manifest differs from the build manifest');
}
if (packagedFiles.some(file => /(^|\/)(src|tests)(\/|$)|\.(?:ts|tsx|vue)$/.test(file))) {
    throw new Error('packaged netlist publication contains development source');
}
NODE
    [[ "$(sha256sum "$extension_root/resources/kernel/yosys.wasm" | awk '{print $1}')" == \
       "$(sha256sum "$validation_dir/extension/resources/kernel/yosys.wasm" | awk '{print $1}')" ]] \
        || fail "packaged yosys.wasm hash does not match the source asset"
    [[ "$(sha256sum "$extension_root/resources/kernel/place.wasm" | awk '{print $1}')" == \
       "$(sha256sum "$validation_dir/extension/resources/kernel/place.wasm" | awk '{print $1}')" ]] \
        || fail "packaged place.wasm hash does not match the signed backend"
    [[ "$(sha256sum "$extension_root/resources/kernel/route.wasm" | awk '{print $1}')" == \
       "$(sha256sum "$validation_dir/extension/resources/kernel/route.wasm" | awk '{print $1}')" ]] \
        || fail "packaged route.wasm hash does not match the signed backend"

    rm -rf "$validation_dir"
    trap - EXIT
}

prebuilt_parser_is_valid() {
    local directory="$server_root/sv-parser/prebuilt/$target"
    local recorded_source_sha="$directory/SOURCE-SHA256"
    [[ -f "$directory/SHA256SUMS" && -f "$recorded_source_sha" ]] && (
        cd "$directory"
        sha256sum -c SHA256SUMS >/dev/null 2>&1
    ) && [[ "$(<"$recorded_source_sha")" == "$(bash "$parser_fingerprint_script")" ]]
}

[[ "$(uname -s)" == "Linux" ]] || fail "this cross-packaging script must run on Linux"
[[ "$(uname -m)" == "x86_64" ]] || fail "the pinned LLVM packages require an x86_64 Linux host"
for command in awk cargo curl dpkg-deb file grep mktemp node npm readlink rm rustup sha256sum unzip; do
    require_command "$command"
done

release_version="$(package_version)"
server_version="$(cargo_version)"
[[ -n "$release_version" ]] || fail "could not read the extension version"
[[ "$release_version" == "$server_version" ]] \
    || fail "version mismatch: extension=$release_version server=$server_version"

log "Preparing the Windows cross-compilation toolchain"
prepare_llvm
export PATH="$llvm_bin:$PATH"
export LD_LIBRARY_PATH="$llvm_lib${LD_LIBRARY_PATH:+:$LD_LIBRARY_PATH}"
clang --version | grep -Fq "clang version $llvm_version" \
    || fail "pinned Clang $llvm_version is not active"

if ! rustup target list --installed | grep -Fxq "$target"; then
    rustup target add "$target"
fi
if ! cargo xwin --version 2>/dev/null | grep -Fq '0.23.0'; then
    log "Installing cargo-xwin 0.23.0"
    cargo install cargo-xwin --version 0.23.0 --locked --force
fi
repair_cargo_xwin_clang_link

if ! prebuilt_parser_is_valid; then
    log "Building the sv-parser Windows native libraries"
    for command in cmake ninja python3; do
        require_command "$command"
    done
    CARGO_TARGET_DIR="$server_root/target/xwin-prebuilt" \
        "$server_root/sv-parser/scripts/build-windows-prebuilt.sh"
fi

log "Verifying the sv-parser Windows native libraries"
(
    cd "$server_root/sv-parser/prebuilt/$target"
    sha256sum -c SHA256SUMS
)

log "Building Digital Server $release_version for Windows x64"
export CARGO_TARGET_DIR="$server_root/target/xwin-clang20"
cargo xwin build \
    --release \
    --locked \
    --target "$target" \
    --xwin-version 17 \
    --bin digital-server \
    --manifest-path "$server_root/Cargo.toml"

built_server="$CARGO_TARGET_DIR/$target/release/digital-server.exe"
built_server_symbols="$CARGO_TARGET_DIR/$target/release/digital_server.pdb"
[[ -f "$built_server" ]] || fail "Windows server was not produced: $built_server"
[[ -f "$built_server_symbols" ]] \
    || fail "Windows server symbols were not produced: $built_server_symbols"
file "$built_server" | grep -Eq 'PE32\+ executable.*x86-64' \
    || fail "built server is not a Windows x86-64 executable"
if [[ "${DIDE_WINDOWS_RUNTIME_SMOKE:-1}" == "1" ]]; then
    if command -v docker >/dev/null 2>&1; then
        log "Testing the Windows LSP backend under Docker/Wine"
        "$server_root/tests/windows/run-docker-wine-lsp-smoke.sh" "$built_server"
    else
        log "Windows runtime smoke NOT_RUN (Docker is unavailable)"
    fi
fi
mkdir -p "$(dirname "$server_resource")"
install -m 0755 "$built_server" "$server_resource"
install -m 0644 "$built_server_symbols" "$server_symbols_resource"
rm -f "$extension_root/resources/server/win32/x64/wave-server.exe"

if [[ "${DIDE_PREPARE_ONLY:-0}" == "1" ]]; then
    log "Windows backend is ready for the universal VSIX"
    exit 0
fi

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

vsix="$dist_dir/fpga-support-$release_version-$platform.vsix"
sha_file="$vsix.sha256"
mkdir -p "$dist_dir"
rm -f "$vsix" "$sha_file"

log "Building and packaging Digital IDE $release_version"
(
    cd "$extension_root"
    npx --yes @vscode/vsce@3.6.2 package \
        --allow-star-activation \
        --target "$platform" \
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
