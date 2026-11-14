#!/usr/bin/env bash
set -euo pipefail
root="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/../.." && pwd)"
cd "${ASTRO_LINUX_RUN_DIR:-$root/Build/RunLinux21564}"
if [[ ! -x AstroBot || ! -f libs/libkernel.prx ]]; then
    echo 'Missing converted game or Linux runtime libraries.' >&2
    exit 1
fi
exec ./AstroBot "$@"
