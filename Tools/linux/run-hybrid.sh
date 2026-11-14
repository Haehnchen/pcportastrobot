#!/usr/bin/env bash
set -euo pipefail
root="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/../.." && pwd)"
cd "${ASTRO_LINUX_RUN_DIR:-$root/Build/RunLinuxHybrid}"
if [[ ! -x AstroBot || ! -f libs/libkyty_gpu.so || ! -f libs/libAstroHybridHost.prx ]]; then
    echo 'Missing Linux Hybrid build; run build-hybrid.sh and stage-hybrid.py first.' >&2
    exit 1
fi
export APS5_GPU_ENGINE=kyty
export KYTY_GPU_HOST_MODULE="$PWD/libs/libAstroHybridHost.prx"
export LD_LIBRARY_PATH="$PWD/libs${LD_LIBRARY_PATH:+:$LD_LIBRARY_PATH}"
if [[ "${ASTROHYBRID_DLSS:-0}" == 1 || "${ASTROHYBRID_DLSSG:-0}" == 1 ]]; then
    export ASTROHYBRID_CUDA_HOLE=1
    export ASTROHYBRID_DLSS_PATH="${ASTROHYBRID_DLSS_PATH:-$PWD/ngx-runtime}"
    if [[ ! -d "$ASTROHYBRID_DLSS_PATH" ]]; then
        echo "Missing NGX runtime directory: $ASTROHYBRID_DLSS_PATH" >&2
        exit 1
    fi
fi
export ASTROHYBRID_FPS_LIMIT="${ASTROHYBRID_FPS_LIMIT:-60}"
export ASTROHYBRID_COMMIT_EPOCH_FASTPATH="${ASTROHYBRID_COMMIT_EPOCH_FASTPATH:-1}"
if [[ -z "${ASTROHYBRID_GAME_STEP_ADDR:-}" ]]; then
    if step_address=$(python3 "$root/Tools/linux/find-game-step.py" ./AstroBot); then
        export ASTROHYBRID_GAME_STEP_ADDR="$step_address"
    fi
fi
if [[ -n "${ASTROHYBRID_GAME_STEP_ADDR:-}" ]]; then
    export ASTROHYBRID_GAME_SPEED="${ASTROHYBRID_GAME_SPEED:-1}"
fi
exec ./AstroBot "$@"
