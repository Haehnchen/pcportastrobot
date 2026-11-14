#!/usr/bin/env bash
set -euo pipefail
root="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/../.." && pwd)"
export KYTY_GPU_PRESENT_MODE="${KYTY_GPU_PRESENT_MODE:-Immediate}"
export ASTROHYBRID_DLSS=1
export ASTROHYBRID_DLSSG="${ASTROHYBRID_DLSSG:-1}"
export ASTROHYBRID_DLSS_PASS="${ASTROHYBRID_DLSS_PASS:-5a34b303576ee324}"
export ASTROHYBRID_DLSS_LEGACY_EXPERIMENT="${ASTROHYBRID_DLSS_LEGACY_EXPERIMENT:-1}"
exec bash "$root/Tools/linux/run-hybrid.sh" "$@"
