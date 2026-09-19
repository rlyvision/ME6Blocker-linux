#!/usr/bin/env bash

# Test script to verify ME6Blocker window rules
# Run this to check if your window manager rules are properly configured

ME6BLOCKER_CLASS="ME6Blocker"
CONFIG_DIR="${HOME}/.config"
LOG_FILE="${HOME}/me6blocker_test.log"

log() {
    echo "[$(date '+%H:%M:%S')] $1" | tee -a "$LOG_FILE"
}

check_all() {
    echo "=== ME6Blocker Window Rules Diagnostic ==="
    echo "Log file: ${LOG_FILE}"
    echo ""

    > "$LOG_FILE"

    # Test Hyprland
    if [ -n "$HYPRLAND_INSTANCE_SIGNATURE" ] || pgrep -i "hyprland" >/dev/null; then
        echo "--- Hyprland ---"
        log "Checking Hyprland..."
        if [ -f "${CONFIG_DIR}/hypr/hyprland.conf" ] && grep -qi "ME6Blocker" "${CONFIG_DIR}/hypr/hyprland.conf"; then
            echo "✓ Config sourced in ~/.config/hypr/hyprland.conf"
            log "✓ Config sourced in hyprland.conf"
        else
            echo "✗ Not sourced in ~/.config/hypr/hyprland.conf"
            log "✗ Not sourced in hyprland.conf"
        fi

        if command -v hyprctl >/dev/null 2>&1; then
            echo "Checking Hyprland live rules for class '${ME6BLOCKER_CLASS}'..."
            rules=$(hyprctl windowrules 2>/dev/null | grep -i -C 1 "${ME6BLOCKER_CLASS}")
            if [ -n "$rules" ]; then
                echo "✓ Live window rules detected:"
                echo "$rules"
            else
                echo "ℹ Note: Hyprland v0.56+ will apply the sourced rule when ${ME6BLOCKER_CLASS} launches."
            fi
        fi
        echo ""
    fi

    # Test i3
    if pgrep -i -x "i3" >/dev/null; then
        echo "--- i3 ---"
        log "Checking i3..."
        if [ -f "${CONFIG_DIR}/i3/config" ] && grep -qi "ME6Blocker" "${CONFIG_DIR}/i3/config"; then
            echo "✓ Rule found in ~/.config/i3/config"
            log "✓ Rule found in i3 config"
        else
            echo "✗ Rule not found in ~/.config/i3/config"
            log "✗ Rule not found in i3 config"
        fi
        echo ""
    fi

    # Test Qtile
    if pgrep -i -x "qtile" >/dev/null; then
        echo "--- Qtile ---"
        log "Checking Qtile..."
        if [ -f "${CONFIG_DIR}/qtile/config.py" ] && grep -qi "ME6Blocker" "${CONFIG_DIR}/qtile/config.py"; then
            echo "✓ Rule found in ~/.config/qtile/config.py"
            log "✓ Rule found in Qtile config"
        else
            echo "✗ Rule not found in ~/.config/qtile/config.py"
            log "✗ Rule not found in Qtile config"
        fi
        echo ""
    fi

    # Test BSPWM
    if pgrep -i -x "bspwm" >/dev/null; then
        echo "--- BSPWM ---"
        log "Checking BSPWM..."
        if grep -qi "ME6Blocker" "${CONFIG_DIR}/bspwm/"* 2>/dev/null; then
            echo "✓ Rule found in BSPWM config"
            log "✓ Rule found in BSPWM config"
        else
            echo "✗ Rule not found in BSPWM config"
            log "✗ Rule not found in BSPWM config"
        fi
        echo ""
    fi

    # Test herbstluftwm
    if pgrep -i -x "herbstluftwm" >/dev/null; then
        echo "--- herbstluftwm ---"
        log "Checking herbstluftwm..."
        if [ -f "${CONFIG_DIR}/herbstluftwm/autostart" ] && grep -qi "ME6Blocker" "${CONFIG_DIR}/herbstluftwm/autostart"; then
            echo "✓ Rule found in herbstluftwm autostart"
            log "✓ Rule found in herbstluftwm autostart"
        else
            echo "✗ Rule not found in herbstluftwm autostart"
            log "✗ Rule not found in herbstluftwm autostart"
        fi
        echo ""
    fi

    echo "Diagnostic complete."
}

check_all
