#!/usr/bin/env bash
set -euo pipefail
root="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/../.." && pwd)"
cmake -S "$root/Tools/kyty-int21" -B "$root/Build/linux-kyty" -G Ninja \
    -DCMAKE_BUILD_TYPE=Release -DCMAKE_C_COMPILER=clang -DCMAKE_CXX_COMPILER=clang++ \
    -DCMAKE_POSITION_INDEPENDENT_CODE=ON -DKYTY_BUILD_LAUNCHER=OFF \
    -DKYTY_BUILD_HYBRID=ON -DBUILD_TESTING=OFF \
    -DKYTY_NGX_SDK_DIR="${KYTY_NGX_SDK_DIR:-}"
cmake --build "$root/Build/linux-kyty" --target kyty_gpu --parallel "${JOBS:-6}"
cmake -S "$root/Tools/AnyPS5" -B "$root/Build/linux-hybrid-host" -G Ninja -DCMAKE_BUILD_TYPE=Release
cmake --build "$root/Build/linux-hybrid-host" --parallel "${JOBS:-6}" --target \
    core/libs/libs/libAstroHybridHost.prx core/libs/libs/libkernel.prx \
    core/libs/libs/libc.prx core/libs/libs/libScePad.prx
