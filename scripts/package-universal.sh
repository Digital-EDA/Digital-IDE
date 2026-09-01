#!/usr/bin/env bash
set -euo pipefail

script_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

DIDE_UNIVERSAL_CHILD=1 DIDE_PREPARE_ONLY=1 \
    bash "$script_dir/package-win32-x64.sh"
DIDE_UNIVERSAL_CHILD=1 \
    bash "$script_dir/package-linux-x64.sh"
