#!/usr/bin/env bash
set -euo pipefail
export ASTRO_LINUX_RUN_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
source "$ASTRO_LINUX_RUN_DIR/Tools/linux/release-menu.sh"
menu=auto
case "${1:-}" in
    --no-menu) menu=off; shift ;;
    --settings) menu=on; shift ;;
esac
if [[ "$menu" == on || ( "$menu" == auto && -t 0 && -t 1 ) ]]; then
    release_menu || exit 0
fi
release_apply
runner="$ASTRO_LINUX_RUN_DIR/Tools/linux/run-dlss-experimental.sh"
if [[ "$ASTROHYBRID_DLSS" != 1 ]]; then
    runner="$ASTRO_LINUX_RUN_DIR/Tools/linux/run-hybrid.sh"
fi
if [[ "${ASTRO_VERBOSE:-0}" == 1 ]]; then
    exec bash "$runner" "$@"
fi
status=0
{ bash "$runner" "$@"; } >/dev/null 2>&1 || status=$?
if (( status != 0 && status != 130 && status != 143 )); then
    printf 'Game exited with error %s. Set ASTRO_VERBOSE=1 for diagnostic output.\n' "$status" >&2
fi
exit "$status"
