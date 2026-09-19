#!/usr/bin/env bash

# ME6Blocker Window Rules Application Script
# Applies floating, sizing, and centering rules for different window managers

ME6BLOCKER_CLASS="ME6Blocker"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CONFIG_DIR="${HOME}/.config"
LOG_FILE="${HOME}/me6blocker_rules.log"

log() {
    echo "[$(date '+%H:%M:%S')] $1" | tee -a "$LOG_FILE"
}

apply_hyprland_rules() {
    log "Applying Hyprland window rules..."
    local hypr_conf="${CONFIG_DIR}/hypr/hyprland.conf"
    local repo_root="$(cd "${SCRIPT_DIR}/.." && pwd)"
    local rule_conf="${repo_root}/config/hyprland-windowrule.conf"

    if [ ! -f "$rule_conf" ]; then
        rule_conf="${HOME}/.local/share/ME6Blocker/hyprland-windowrule.conf"
    fi

    if [ ! -f "$hypr_conf" ]; then
        log "✗ hyprland.conf not found at $hypr_conf"
        return 1
    fi

    if grep -q "ME6Blocker/hyprland-windowrule.conf" "$hypr_conf" 2>/dev/null; then
        log "✓ ME6Blocker config is already sourced in hyprland.conf"
    elif grep -q "hyprland-windowrule.conf" "$hypr_conf" 2>/dev/null; then
        log "✓ Hyprland rule source already configured in hyprland.conf"
    else
        log "Adding ME6Blocker config source to hyprland.conf..."
        echo -e "\nsource = ${rule_conf}" >> "$hypr_conf"
        log "✓ Source line appended to hyprland.conf"
    fi

    # Reload Hyprland configuration to apply rules immediately
    if command -v hyprctl >/dev/null 2>&1; then
        log "Reloading Hyprland config..."
        hyprctl reload 2>&1 | tee -a "$LOG_FILE"
        log "✓ Hyprland reloaded"
    fi
}

apply_i3_rules() {
    log "Applying i3 window rules..."
    local i3_conf="${CONFIG_DIR}/i3/config"

    if [ ! -f "$i3_conf" ]; then
        mkdir -p "${CONFIG_DIR}/i3"
        touch "$i3_conf"
    fi

    if grep -qi "ME6Blocker" "$i3_conf" 2>/dev/null; then
        log "✓ ME6Blocker rules already found in i3 config"
    else
        log "Adding ME6Blocker rules to i3 config..."
        cat >> "$i3_conf" <<EOF

# ME6Blocker window rules
for_window [class="^${ME6BLOCKER_CLASS}$"] floating enable, resize set 360 800, move position center
EOF
        log "✓ Rules added to i3 config"
    fi

    if command -v i3-msg >/dev/null 2>&1; then
        i3-msg reload >/dev/null 2>&1 && log "✓ i3 reloaded"
    fi
}

apply_qtile_rules() {
    log "Applying Qtile window rules..."
    local qtile_conf="${CONFIG_DIR}/qtile/config.py"

    if [ ! -f "$qtile_conf" ]; then
        log "✗ Qtile config not found at $qtile_conf"
        return 1
    fi

    if grep -qi "ME6Blocker" "$qtile_conf" 2>/dev/null; then
        log "✓ ME6Blocker rules already found in Qtile config"
    else
        log "Adding ME6Blocker rules to Qtile config..."
        cat >> "$qtile_conf" <<EOF

# ME6Blocker floating rule
from libqtile.config import Match
floating_layout.float_rules.append(Match(wm_class="${ME6BLOCKER_CLASS}"))
EOF
        log "✓ Rules added to Qtile config"
    fi
}

apply_bspwm_rules() {
    log "Applying BSPWM window rules..."
    local bspwm_conf="${CONFIG_DIR}/bspwm/bspwmrc"

    if [ ! -f "$bspwm_conf" ]; then
        bspwm_conf="${CONFIG_DIR}/bspwm/rc.conf"
    fi

    if [ -f "$bspwm_conf" ] && grep -qi "ME6Blocker" "$bspwm_conf" 2>/dev/null; then
        log "✓ ME6Blocker rules already found in BSPWM config"
    elif [ -f "$bspwm_conf" ]; then
        log "Adding ME6Blocker rules to BSPWM config..."
        cat >> "$bspwm_conf" <<EOF

# ME6Blocker window rules
bspc rule -a "${ME6BLOCKER_CLASS}" state=floating rectangle=360x800+0+0 center=on
EOF
        log "✓ Rules added to BSPWM config"
    fi

    if command -v bspc >/dev/null 2>&1; then
        bspc rule -a "${ME6BLOCKER_CLASS}" state=floating rectangle=360x800+0+0 center=on 2>/dev/null
        log "✓ Dynamic BSPWM rule applied"
    fi
}

apply_herbstluftwm_rules() {
    log "Applying herbstluftwm window rules..."
    local herbst_conf="${CONFIG_DIR}/herbstluftwm/autostart"

    if [ -f "$herbst_conf" ]; then
        if grep -qi "ME6Blocker" "$herbst_conf" 2>/dev/null; then
            log "✓ ME6Blocker rules already found in herbstluftwm autostart"
        else
            cat >> "$herbst_conf" <<EOF

# ME6Blocker window rules
hc rule class="${ME6BLOCKER_CLASS}" floating=on
EOF
            log "✓ Rules added to herbstluftwm autostart"
        fi
    fi

    if command -v herbstclient >/dev/null 2>&1; then
        herbstclient rule class="${ME6BLOCKER_CLASS}" floating=on 2>/dev/null
        log "✓ herbstluftwm live rule applied"
    fi
}

verify_rules() {
    local target="$1"
    log "Verifying window rules for: ${target:-auto-detected WM}..."

    # Auto detect if not provided
    if [ -z "$target" ]; then
        if [ -n "$HYPRLAND_INSTANCE_SIGNATURE" ] || pgrep -i -x "hyprland" >/dev/null || pgrep -i "hyprland" >/dev/null; then
            target="hyprland"
        elif pgrep -i -x "i3" >/dev/null; then
            target="i3"
        elif pgrep -i -x "qtile" >/dev/null; then
            target="qtile"
        elif pgrep -i -x "bspwm" >/dev/null; then
            target="bspwm"
        elif pgrep -i -x "herbstluftwm" >/dev/null; then
            target="herbstluftwm"
        fi
    fi

    case "${target,,}" in
        hyprland)
            if [ -f "${CONFIG_DIR}/hypr/hyprland.conf" ] && grep -q "ME6Blocker" "${CONFIG_DIR}/hypr/hyprland.conf" 2>/dev/null; then
                echo "✓ Hyprland: Sourced in hyprland.conf"
            else
                echo "✗ Hyprland: Source line NOT found in ~/.config/hypr/hyprland.conf"
                return 1
            fi
            if command -v hyprctl >/dev/null 2>&1; then
                echo "--- Active Hyprland window rules matching ME6Blocker ---"
                hyprctl windowrules 2>/dev/null | grep -i -C 2 "ME6Blocker" || echo "(Rule sourced, will match when window spawns with class: ME6Blocker)"
            fi
            return 0
            ;;
        i3)
            if grep -qi "ME6Blocker" "${CONFIG_DIR}/i3/config" 2>/dev/null; then
                echo "✓ i3: Rule found in ~/.config/i3/config"
                return 0
            else
                echo "✗ i3: Rule NOT found in ~/.config/i3/config"
                return 1
            fi
            ;;
        qtile)
            if grep -qi "ME6Blocker" "${CONFIG_DIR}/qtile/config.py" 2>/dev/null; then
                echo "✓ Qtile: Rule found in ~/.config/qtile/config.py"
                return 0
            else
                echo "✗ Qtile: Rule NOT found in ~/.config/qtile/config.py"
                return 1
            fi
            ;;
        bspwm)
            if grep -qi "ME6Blocker" "${CONFIG_DIR}/bspwm/bspwmrc" 2>/dev/null || grep -qi "ME6Blocker" "${CONFIG_DIR}/bspwm/rc.conf" 2>/dev/null; then
                echo "✓ BSPWM: Rule found in bspwm config"
                return 0
            else
                echo "✗ BSPWM: Rule NOT found in bspwm config"
                return 1
            fi
            ;;
        herbstluftwm)
            if grep -qi "ME6Blocker" "${CONFIG_DIR}/herbstluftwm/autostart" 2>/dev/null; then
                echo "✓ herbstluftwm: Rule found in autostart"
                return 0
            else
                echo "✗ herbstluftwm: Rule NOT found in autostart"
                return 1
            fi
            ;;
        *)
            echo "Unknown window manager: $target"
            echo "Usage: $0 verify [hyprland|i3|qtile|bspwm|herbstluftwm]"
            return 1
            ;;
    esac
}

detect_and_apply() {
    local target="$1"

    if [ -n "$target" ]; then
        case "${target,,}" in
            hyprland)     apply_hyprland_rules ;;
            i3)           apply_i3_rules ;;
            qtile)        apply_qtile_rules ;;
            bspwm)        apply_bspwm_rules ;;
            herbstluftwm) apply_herbstluftwm_rules ;;
            *)
                echo "Unsupported window manager argument: $target"
                echo "Supported: hyprland, i3, qtile, bspwm, herbstluftwm"
                return 1
                ;;
        esac
        return 0
    fi

    log "Detecting running window manager..."
    if [ -n "$HYPRLAND_INSTANCE_SIGNATURE" ] || pgrep -i -x "hyprland" >/dev/null || pgrep -i "hyprland" >/dev/null; then
        echo "Detected: Hyprland"
        apply_hyprland_rules
    elif pgrep -i -x "i3" >/dev/null; then
        echo "Detected: i3"
        apply_i3_rules
    elif pgrep -i -x "qtile" >/dev/null; then
        echo "Detected: Qtile"
        apply_qtile_rules
    elif pgrep -i -x "bspwm" >/dev/null; then
        echo "Detected: BSPWM"
        apply_bspwm_rules
    elif pgrep -i -x "herbstluftwm" >/dev/null; then
        echo "Detected: herbstluftwm"
        apply_herbstluftwm_rules
    else
        echo "Could not auto-detect window manager."
        echo "Please specify one: $0 [hyprland|i3|qtile|bspwm|herbstluftwm]"
        return 1
    fi
}

remove_rules() {
    log "Removing ME6Blocker window rules from all window managers..."

    # Hyprland
    local hypr_conf="${CONFIG_DIR}/hypr/hyprland.conf"
    if [ -f "$hypr_conf" ] && grep -qi "hyprland-windowrule.conf\|ME6Blocker" "$hypr_conf"; then
        sed -i '/ME6Blocker/d; /hyprland-windowrule\.conf/d' "$hypr_conf"
        log "✓ Removed rules from ~/.config/hypr/hyprland.conf"
        if command -v hyprctl >/dev/null 2>&1; then
            hyprctl reload >/dev/null 2>&1 && log "✓ Hyprland reloaded"
        fi
    fi

    # i3
    local i3_conf="${CONFIG_DIR}/i3/config"
    if [ -f "$i3_conf" ] && grep -qi "ME6Blocker" "$i3_conf"; then
        sed -i '/ME6Blocker/d; /class="\^ME6Blocker\$"/d; /title="\^ME6Blocker\$"/d' "$i3_conf"
        log "✓ Removed rules from ~/.config/i3/config"
        if command -v i3-msg >/dev/null 2>&1; then
            i3-msg reload >/dev/null 2>&1 && log "✓ i3 reloaded"
        fi
    fi

    # Qtile
    local qtile_conf="${CONFIG_DIR}/qtile/config.py"
    if [ -f "$qtile_conf" ] && grep -qi "ME6Blocker" "$qtile_conf"; then
        sed -i '/ME6Blocker/d' "$qtile_conf"
        log "✓ Removed rules from ~/.config/qtile/config.py"
    fi

    # BSPWM
    local bspwm_conf="${CONFIG_DIR}/bspwm/bspwmrc"
    if [ -f "$bspwm_conf" ] && grep -qi "ME6Blocker" "$bspwm_conf"; then
        sed -i '/ME6Blocker/d' "$bspwm_conf"
        log "✓ Removed rules from ~/.config/bspwm/bspwmrc"
    fi

    # herbstluftwm
    local herbst_conf="${CONFIG_DIR}/herbstluftwm/autostart"
    if [ -f "$herbst_conf" ] && grep -qi "ME6Blocker" "$herbst_conf"; then
        sed -i '/ME6Blocker/d' "$herbst_conf"
        log "✓ Removed rules from ~/.config/herbstluftwm/autostart"
    fi
}

main() {
    echo "================================="
    echo " ME6Blocker Window Rules Manager"
    echo "================================="

    if [ "$1" = "verify" ]; then
        verify_rules "$2"
        exit $?
    fi

    if [ "$1" = "remove" ] || [ "$1" = "--remove" ] || [ "$1" = "-r" ] || [ "$1" = "uninstall" ]; then
        remove_rules
        exit 0
    fi

    detect_and_apply "$1"

    echo ""
    echo "Done! Check ${LOG_FILE} for details."
    echo "To verify rules, run: $0 verify"
}

main "$@"
