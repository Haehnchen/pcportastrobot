#!/usr/bin/env bash
set -euo pipefail
root="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/../.." && pwd)"
source_dir="$root/Tools/AnyPS5"
if [[ ! -f "$source_dir/CMakeLists.txt" ]]; then
    echo 'Missing Tools/AnyPS5; clone boykopovar/AnyPS5 and checkout 319621ba2e578bd053b0baba2877fe70520e0737.' >&2
    exit 1
fi
cmake -S "$source_dir" -B "$root/Build/linux-runtime" -G Ninja -DCMAKE_BUILD_TYPE=Release
cmake --build "$root/Build/linux-runtime" --target libs --parallel "${JOBS:-6}"
