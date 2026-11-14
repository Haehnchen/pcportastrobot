#!/usr/bin/env bash
set -euo pipefail
root="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/../.." && pwd)"
output="${1:-$root/Build/RunLinuxRelease}"
sdk="${KYTY_NGX_SDK_DIR:-$root/Build/sdk/DLSS}"
source="${ASTRO_LINUX_SOURCE_DIR:-$root/Build/RunLinux21564}"
if [[ -e "$output" ]]; then
    echo "Output already exists: $output; pass a new output directory as the first argument." >&2
    exit 1
fi
if [[ ! -d "$sdk/lib/Linux_x86_64/rel" || ! -x "$source/AstroBot" ]]; then
    echo 'Requires the Linux DLSS SDK and a converted game; see Source/linux/README.txt.' >&2
    exit 1
fi
command -v strip >/dev/null
env KYTY_NGX_SDK_DIR="$sdk" bash "$root/Tools/linux/build-hybrid.sh"
python3 "$root/Tools/linux/stage-hybrid.py" --source "$source" --output "$output" --ngx-sdk "$sdk"
for library in libkyty_gpu.so libc.prx libkernel.prx libScePad.prx libAstroHybridHost.prx libSceAgc.prx libSceAgcDriver.prx libSceVideoOut.prx; do
    strip --strip-unneeded "$output/libs/$library"
done
mkdir -p "$output/Tools/linux"
cp "$root/Tools/linux/"{run-hybrid.sh,run-dlss-experimental.sh,find-game-step.py,release-menu.sh} "$output/Tools/linux/"
cp "$root/Tools/linux/play-release.sh" "$output/play.sh"
chmod +x "$output/play.sh"
printf 'Release build ready: %s/play.sh\nDLSS SR and experimental 2x Frame Generation enabled by default.\nGame data and additional runtime libraries still use local symlinks.\n' "$output"
