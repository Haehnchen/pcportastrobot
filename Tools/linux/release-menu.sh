#!/usr/bin/env bash
export KYTY_GPU_FULLSCREEN="${KYTY_GPU_FULLSCREEN:-0}"
export KYTY_GPU_WIDTH="${KYTY_GPU_WIDTH:-1280}"
export KYTY_GPU_HEIGHT="${KYTY_GPU_HEIGHT:-720}"
export ASTROHYBRID_DLSS="${ASTROHYBRID_DLSS:-1}"
export ASTROHYBRID_DLSS_QUALITY="${ASTROHYBRID_DLSS_QUALITY:-performance}"
export ASTROHYBRID_DLSSG="${ASTROHYBRID_DLSSG:-1}"
export ASTROHYBRID_OVERLAY="${ASTROHYBRID_OVERLAY:-off}"
export ASTROHYBRID_LOW_LATENCY="${ASTROHYBRID_LOW_LATENCY:-1}"
export KYTY_GPU_PRESENT_MODE="${KYTY_GPU_PRESENT_MODE:-Immediate}"
export ASTROHYBRID_GAME_SPEED_PERCENT="${ASTROHYBRID_GAME_SPEED_PERCENT:-100}"
release_fps="${ASTROHYBRID_FPS_LIMIT:-60}"
release_target="${ASTRO_LINUX_FG_TARGET:-120}"
release_fg="${ASTRO_LINUX_FG_MODE:-2x}"
case "$release_target" in 0|50|60|90|120|144|165) ;; *) release_target=120 ;; esac
case "$release_fg" in off|auto|2x|3x|4x) ;; *) release_fg=2x ;; esac
if [[ "$ASTROHYBRID_DLSSG" != 1 || "$ASTROHYBRID_DLSS" != 1 ]]; then
    release_fg=off
elif [[ -z "${ASTRO_LINUX_FG_MODE:-}" ]]; then
    if [[ "${ASTROHYBRID_DLSSG_TARGET:-0}" != 0 ]]; then
        release_fg=auto
        case "$ASTROHYBRID_DLSSG_TARGET" in
            50|60|90|120|144|165) release_target="$ASTROHYBRID_DLSSG_TARGET" ;;
        esac
    else
        case "${ASTROHYBRID_DLSSG_FRAMES:-1}" in
            2) release_fg=3x ;;
            3) release_fg=4x ;;
        esac
    fi
fi

release_cycle() {
    local -n setting="$1"
    shift
    local first="$1" previous='' value
    for value in "$@"; do
        if [[ "$previous" == "$setting" ]]; then setting="$value"; return; fi
        previous="$value"
    done
    setting="$first"
}

release_apply() {
    export ASTROHYBRID_FPS_LIMIT="$release_fps"
    export ASTROHYBRID_DLSSG=0 ASTROHYBRID_DLSSG_TARGET=0 ASTROHYBRID_DLSSG_FRAMES=1 ASTROHYBRID_DLSSG_MAX_FRAMES=3
    if [[ "$ASTROHYBRID_DLSS" != 1 ]]; then release_fg=off; fi
    if [[ "$release_fg" != off ]]; then
        local multiplier=2 limit
        case "$release_fg" in 3x) multiplier=3 ;; 4x) multiplier=4 ;; esac
        export ASTROHYBRID_DLSSG=1 ASTROHYBRID_DLSSG_FRAMES="$((multiplier - 1))"
        if [[ "$release_target" == 0 ]]; then
            export ASTROHYBRID_FPS_LIMIT=unlimited
        else
            limit=$((release_target / multiplier))
            (( limit < 30 )) && limit=30
            export ASTROHYBRID_FPS_LIMIT="$limit"
            if [[ "$release_fg" == auto ]]; then export ASTROHYBRID_DLSSG_TARGET="$release_target"; fi
        fi
        export KYTY_GPU_PRESENT_MODE=Immediate
    fi
}

release_menu() {
    local choice screen dlss target latency vsync
    while true; do
        release_apply
        screen=Windowed; [[ "$KYTY_GPU_FULLSCREEN" == 1 ]] && screen='Desktop fullscreen'
        dlss="$ASTROHYBRID_DLSS_QUALITY"; [[ "$ASTROHYBRID_DLSS" != 1 ]] && dlss="Game's own"
        target="$release_target FPS"; [[ "$release_target" == 0 ]] && target=Unlimited
        latency=Off; [[ "$ASTROHYBRID_LOW_LATENCY" == 1 ]] && latency=On
        vsync=Off; [[ "$KYTY_GPU_PRESENT_MODE" == Fifo ]] && vsync=On
        printf '\nAstro — Linux graphics settings\n\n'
        printf '  1  Display:           %s\n' "$screen"
        printf '  2  Window size:       %s x %s\n' "$KYTY_GPU_WIDTH" "$KYTY_GPU_HEIGHT"
        printf '  3  Upscaling preset:  %s\n' "$dlss"
        printf '  4  Frame generation:  %s\n' "$release_fg"
        printf '  5  FG display target: %s\n' "$target"
        printf '  6  Base FPS limit:    %s (effective: %s)\n' "$release_fps" "$ASTROHYBRID_FPS_LIMIT"
        printf '  7  VSync:             %s\n' "$vsync"
        printf '  8  Low latency:       %s\n' "$latency"
        printf '  9  Statistics:        %s\n' "$ASTROHYBRID_OVERLAY"
        printf ' 10  Game speed:        %s%%\n' "$ASTROHYBRID_GAME_SPEED_PERCENT"
        printf '\nEnter starts with these settings. Type an option number to cycle it.\n'
        printf 'DLSS presets do not force render resolution. F11 toggles fullscreen.\n'
        printf 'FG is experimental and hardware-limited; its target sets the base FPS cap\n'
        printf '(minimum 30). Actual FPS can be lower. VSync requires FG off.\n'
        printf '\nEnter = Play | 1–10 = Change | q = Quit: '
        if ! IFS= read -r choice; then return 1; fi
        case "$choice" in
            '') return 0 ;;
            1) release_cycle KYTY_GPU_FULLSCREEN 1 0 ;;
            2) release_cycle KYTY_GPU_WIDTH 1280 1600 1920 2560 3840
               case "$KYTY_GPU_WIDTH" in
                   1280) KYTY_GPU_HEIGHT=720 ;; 1600) KYTY_GPU_HEIGHT=900 ;;
                   1920) KYTY_GPU_HEIGHT=1080 ;; 2560) KYTY_GPU_HEIGHT=1440 ;;
                   3840) KYTY_GPU_HEIGHT=2160 ;;
               esac ;;
            3) if [[ "$ASTROHYBRID_DLSS" != 1 ]]; then
                   ASTROHYBRID_DLSS=1; ASTROHYBRID_DLSS_QUALITY=quality
               elif [[ "$ASTROHYBRID_DLSS_QUALITY" == dlaa ]]; then
                   ASTROHYBRID_DLSS=0; release_fg=off
               else
                   release_cycle ASTROHYBRID_DLSS_QUALITY quality balanced performance dlaa
               fi ;;
            4) if [[ "$ASTROHYBRID_DLSS" == 1 ]]; then
                   release_cycle release_fg off auto 2x 3x 4x
               else
                   printf '\nEnable DLSS before enabling frame generation.\n'
               fi ;;
            5) release_cycle release_target 0 50 60 90 120 144 165 ;;
            6) if [[ "$release_fg" == off ]]; then
                   release_cycle release_fps 30 35 45 50 55 60 unlimited
               else
                   printf '\nWith FG enabled, change the FG display target instead.\n'
               fi ;;
            7) if [[ "$release_fg" == off ]]; then
                   release_cycle KYTY_GPU_PRESENT_MODE Immediate Fifo
               else
                   printf '\nTurn frame generation off to enable VSync.\n'
               fi ;;
            8) release_cycle ASTROHYBRID_LOW_LATENCY 0 1 ;;
            9) release_cycle ASTROHYBRID_OVERLAY off fps compact full ;;
            10) release_cycle ASTROHYBRID_GAME_SPEED_PERCENT 100 95 90 85 80 75 ;;
            q|Q) return 1 ;;
            *) printf '\nEnter an option from 1 to 10, Enter, or q.\n' ;;
        esac
    done
}
