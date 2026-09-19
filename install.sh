#!/usr/bin/env bash

# ==============================================================================
# ME6Blocker Linux Installation Script
# Installs application, desktop launcher, icons, CLI binary, and WM rules
# ==============================================================================

set -e

APP_NAME="ME6Blocker"
BIN_NAME="me6blocker"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Installation paths
INSTALL_DIR="${HOME}/.local/share/ME6Blocker"
BIN_DIR="${HOME}/.local/bin"
DESKTOP_DIR="${HOME}/.local/share/applications"
ICON_DIR_256="${HOME}/.local/share/icons/hicolor/256x256/apps"
ICON_DIR_DEFAULT="${HOME}/.local/share/icons"
PIXMAPS_DIR="${HOME}/.local/share/pixmaps"
AUTOSTART_DIR="${HOME}/.config/autostart"
CONFIG_DIR="${HOME}/.config"

# Colors for output
C_RESET="\033[0m"
C_RED="\033[1;31m"
C_GREEN="\033[1;32m"
C_YELLOW="\033[1;33m"
C_BLUE="\033[1;34m"
C_CYAN="\033[1;36m"
C_BOLD="\033[1m"

log_info() {
    echo -e "${C_BLUE}ℹ${C_RESET} $1"
}

log_success() {
    echo -e "${C_GREEN}✓${C_RESET} $1"
}

log_warn() {
    echo -e "${C_YELLOW}⚠${C_RESET} $1"
}

log_error() {
    echo -e "${C_RED}✗${C_RESET} $1"
}

banner() {
    echo -e "${C_CYAN}${C_BOLD}"
    echo "=================================================="
    echo "         ME6Blocker Linux Installer               "
    echo "=================================================="
    echo -e "${C_RESET}"
}

check_dependencies() {
    log_info "Checking system requirements..."

    # Check Python 3
    if ! command -v python3 >/dev/null 2>&1; then
        log_error "Python 3 is required but not installed."
        exit 1
    fi
    local py_version
    py_version=$(python3 -c "import sys; print('.'.join(map(str, sys.version_info[:2])))")
    log_success "Found Python ${py_version}"

    # Check PySide6 and requests
    if ! python3 -c "import PySide6, requests" >/dev/null 2>&1; then
        log_warn "Required Python modules (PySide6, requests) are missing."
        log_info "Attempting to install Python dependencies via pip..."
        if command -v pip >/dev/null 2>&1 || command -v pip3 >/dev/null 2>&1; then
            pip install -r "${SCRIPT_DIR}/requirements.txt" || pip3 install -r "${SCRIPT_DIR}/requirements.txt" || {
                log_warn "pip install had warnings or requires --break-system-packages. Trying with flag..."
                pip install -r "${SCRIPT_DIR}/requirements.txt" --break-system-packages 2>/dev/null || true
            }
        else
            log_warn "pip not found. Please ensure PySide6 and requests are installed (e.g. 'sudo pacman -S python-pyside6 python-requests' on Arch)."
        fi
    else
        log_success "Python dependencies verified (PySide6, requests)"
    fi

    # Check iptables
    if ! command -v iptables >/dev/null 2>&1 && ! command -v iptables-nft >/dev/null 2>&1; then
        log_warn "iptables / iptables-nft not found in PATH."
        log_info "ME6Blocker requires iptables to manage firewall rules."
        log_info "On Arch Linux: sudo pacman -S iptables"
        log_info "On Debian/Ubuntu: sudo apt install iptables"
        log_info "On Fedora: sudo dnf install iptables"
    else
        log_success "iptables firewall utility found"
    fi

    # Check pkexec
    if command -v pkexec >/dev/null 2>&1; then
        log_success "pkexec authentication agent found"
    elif command -v sudo >/dev/null 2>&1; then
        log_info "pkexec not found, sudo will be used for privilege escalation."
    fi
}

generate_icons() {
    log_info "Preparing application icons..."
    mkdir -p "${ICON_DIR_256}" "${ICON_DIR_DEFAULT}" "${PIXMAPS_DIR}"

    local icon_src_png="${SCRIPT_DIR}/assets/logo.png"
    local icon_src_ico="${SCRIPT_DIR}/assets/logo.ico"
    [ ! -f "$icon_src_png" ] && [ -f "${SCRIPT_DIR}/logo.png" ] && icon_src_png="${SCRIPT_DIR}/logo.png"
    [ ! -f "$icon_src_ico" ] && [ -f "${SCRIPT_DIR}/logo.ico" ] && icon_src_ico="${SCRIPT_DIR}/logo.ico"

    # Generate logo.png from logo.ico if needed
    if [ ! -f "$icon_src_png" ] && [ -f "$icon_src_ico" ]; then
        python3 -c "import sys; from PySide6.QtWidgets import QApplication; from PySide6.QtGui import QIcon; app = QApplication(sys.argv); icon = QIcon('${icon_src_ico}'); pixmap = icon.pixmap(256, 256); pixmap.save('${SCRIPT_DIR}/assets/logo.png')" 2>/dev/null || true
        icon_src_png="${SCRIPT_DIR}/assets/logo.png"
    fi

    if [ -f "$icon_src_png" ]; then
        cp "$icon_src_png" "${ICON_DIR_256}/me6blocker.png"
        cp "$icon_src_png" "${ICON_DIR_DEFAULT}/me6blocker.png"
        cp "$icon_src_png" "${PIXMAPS_DIR}/me6blocker.png"
        log_success "Icons installed to icon themes"
    elif [ -f "$icon_src_ico" ]; then
        cp "$icon_src_ico" "${ICON_DIR_DEFAULT}/me6blocker.ico"
        log_success "Icon installed (ico format)"
    fi

    # Update GTK icon cache if tool exists
    if command -v gtk-update-icon-cache >/dev/null 2>&1; then
        gtk-update-icon-cache -f -t "${HOME}/.local/share/icons/hicolor" 2>/dev/null || true
    fi
}

install_application() {
    log_info "Installing ME6Blocker to ${INSTALL_DIR}..."
    mkdir -p "${INSTALL_DIR}" "${INSTALL_DIR}/assets" "${INSTALL_DIR}/config" "${BIN_DIR}" "${DESKTOP_DIR}"

    # Copy application files
    cp "${SCRIPT_DIR}/me6blocklinux.py" "${INSTALL_DIR}/me6blocklinux.py"
    chmod +x "${INSTALL_DIR}/me6blocklinux.py"

    # Copy assets
    if [ -d "${SCRIPT_DIR}/assets" ]; then
        cp -r "${SCRIPT_DIR}/assets/"* "${INSTALL_DIR}/assets/" 2>/dev/null || true
    fi
    if [ -f "${SCRIPT_DIR}/assets/logo.ico" ]; then
        cp "${SCRIPT_DIR}/assets/logo.ico" "${INSTALL_DIR}/logo.ico"
    fi
    if [ -f "${SCRIPT_DIR}/assets/logo.png" ]; then
        cp "${SCRIPT_DIR}/assets/logo.png" "${INSTALL_DIR}/logo.png"
    fi

    # Copy config
    local wm_rule_src="${SCRIPT_DIR}/config/hyprland-windowrule.conf"
    [ ! -f "$wm_rule_src" ] && [ -f "${SCRIPT_DIR}/hyprland-windowrule.conf" ] && wm_rule_src="${SCRIPT_DIR}/hyprland-windowrule.conf"
    if [ -f "$wm_rule_src" ]; then
        cp "$wm_rule_src" "${INSTALL_DIR}/hyprland-windowrule.conf"
        cp "$wm_rule_src" "${INSTALL_DIR}/config/hyprland-windowrule.conf" 2>/dev/null || true
    fi

    # Create CLI binary launcher in ~/.local/bin/me6blocker
    cat > "${BIN_DIR}/${BIN_NAME}" <<EOF
#!/usr/bin/env bash
# ME6Blocker CLI Launcher
SCRIPT_PATH="${INSTALL_DIR}/me6blocklinux.py"
exec python3 "\$SCRIPT_PATH" "\$@"
EOF
    chmod +x "${BIN_DIR}/${BIN_NAME}"
    log_success "Created CLI command: ${BIN_DIR}/${BIN_NAME}"

    # Create Desktop Entry in ~/.local/share/applications/me6blocker.desktop
    log_info "Creating desktop entry in ${DESKTOP_DIR}/me6blocker.desktop..."
    cat > "${DESKTOP_DIR}/me6blocker.desktop" <<EOF
[Desktop Entry]
Type=Application
Name=ME6Blocker
GenericName=Rocket League Server Blocker
Comment=Block high ping Middle East Rocket League servers dynamically via firewall
Exec=python3 "${INSTALL_DIR}/me6blocklinux.py"
Icon=me6blocker
Terminal=false
Categories=Game;Network;Utility;Qt;
StartupWMClass=ME6Blocker
Keywords=RocketLeague;Server;Blocker;Firewall;ME6;
X-Purism-FormFactor=Workstation;Mobile;
EOF
    chmod +x "${DESKTOP_DIR}/me6blocker.desktop"
    log_success "Desktop entry created successfully"

    # Update desktop database
    if command -v update-desktop-database >/dev/null 2>&1; then
        update-desktop-database "${DESKTOP_DIR}" 2>/dev/null || true
    fi
}

setup_wm_rules() {
    log_info "Configuring Window Manager floating and sizing rules..."

    local installed_rule_conf="${INSTALL_DIR}/hyprland-windowrule.conf"

    # Hyprland
    local hypr_conf="${CONFIG_DIR}/hypr/hyprland.conf"
    if [ -d "${CONFIG_DIR}/hypr" ] || [ -n "$HYPRLAND_INSTANCE_SIGNATURE" ] || pgrep -i "hyprland" >/dev/null; then
        if [ -f "$hypr_conf" ]; then
            # Clean up old source lines if any and point to installed location
            if grep -q "ME6Blocker/hyprland-windowrule.conf" "$hypr_conf"; then
                log_success "Hyprland rule source already configured in hyprland.conf"
            else
                echo -e "\n# ME6Blocker Window Rules\nsource = ${installed_rule_conf}" >> "$hypr_conf"
                log_success "Added ME6Blocker rules source to ~/.config/hypr/hyprland.conf"
            fi
            if command -v hyprctl >/dev/null 2>&1; then
                hyprctl reload >/dev/null 2>&1 && log_success "Hyprland configuration reloaded"
            fi
        fi
    fi

    # i3
    local i3_conf="${CONFIG_DIR}/i3/config"
    if [ -d "${CONFIG_DIR}/i3" ] || pgrep -i -x "i3" >/dev/null; then
        mkdir -p "${CONFIG_DIR}/i3"
        if ! grep -qi "ME6Blocker" "$i3_conf" 2>/dev/null; then
            cat >> "$i3_conf" <<'EOF'

# ME6Blocker window rules
for_window [class="^ME6Blocker$"] floating enable, resize set 360 800, move position center
for_window [title="^ME6Blocker$"] floating enable, resize set 360 800, move position center
EOF
            log_success "Added ME6Blocker rules to i3 config"
            if command -v i3-msg >/dev/null 2>&1; then
                i3-msg reload >/dev/null 2>&1 || true
            fi
        fi
    fi

    # Qtile
    local qtile_conf="${CONFIG_DIR}/qtile/config.py"
    if [ -f "$qtile_conf" ]; then
        if ! grep -qi "ME6Blocker" "$qtile_conf" 2>/dev/null; then
            cat >> "$qtile_conf" <<'EOF'

# ME6Blocker floating rule
from libqtile.config import Match
try:
    floating_layout.float_rules.extend([
        Match(wm_class="ME6Blocker"),
        Match(title="ME6Blocker")
    ])
except Exception:
    pass
EOF
            log_success "Added ME6Blocker rules to Qtile config"
        fi
    fi

    # BSPWM
    local bspwm_conf="${CONFIG_DIR}/bspwm/bspwmrc"
    if [ -f "$bspwm_conf" ]; then
        if ! grep -qi "ME6Blocker" "$bspwm_conf" 2>/dev/null; then
            cat >> "$bspwm_conf" <<'EOF'

# ME6Blocker window rules
bspc rule -a "ME6Blocker" state=floating rectangle=360x800+0+0 center=on
EOF
            log_success "Added ME6Blocker rules to BSPWM config"
        fi
    fi
}

remove_wm_rules() {
    log_info "Removing Window Manager configuration rules..."

    # Hyprland
    local hypr_conf="${CONFIG_DIR}/hypr/hyprland.conf"
    if [ -f "$hypr_conf" ]; then
        if grep -qi "hyprland-windowrule.conf\|ME6Blocker" "$hypr_conf"; then
            sed -i '/ME6Blocker/d; /hyprland-windowrule\.conf/d' "$hypr_conf"
            log_success "Removed ME6Blocker rules from ~/.config/hypr/hyprland.conf"
            if command -v hyprctl >/dev/null 2>&1; then
                hyprctl reload >/dev/null 2>&1 && log_success "Hyprland configuration reloaded"
            fi
        fi
    fi

    # i3
    local i3_conf="${CONFIG_DIR}/i3/config"
    if [ -f "$i3_conf" ]; then
        if grep -qi "ME6Blocker" "$i3_conf"; then
            sed -i '/ME6Blocker/d; /class="\^ME6Blocker\$"/d; /title="\^ME6Blocker\$"/d' "$i3_conf"
            log_success "Removed ME6Blocker rules from ~/.config/i3/config"
            if command -v i3-msg >/dev/null 2>&1; then
                i3-msg reload >/dev/null 2>&1 || true
            fi
        fi
    fi

    # Qtile
    local qtile_conf="${CONFIG_DIR}/qtile/config.py"
    if [ -f "$qtile_conf" ]; then
        if grep -qi "ME6Blocker" "$qtile_conf"; then
            python3 -c "
with open('${qtile_conf}', 'r') as f:
    lines = f.readlines()
new_lines = []
skip = False
for line in lines:
    if '# ME6Blocker' in line:
        skip = True
        continue
    if skip and any(k in line for k in ['floating_layout', 'Match(wm_class=\"ME6Blocker\")', 'Match(title=\"ME6Blocker\")', 'except Exception', 'pass']):
        continue
    skip = False
    new_lines.append(line)
with open('${qtile_conf}', 'w') as f:
    f.writelines(new_lines)
" 2>/dev/null || sed -i '/ME6Blocker/d' "$qtile_conf"
            log_success "Removed ME6Blocker rules from ~/.config/qtile/config.py"
        fi
    fi

    # BSPWM
    local bspwm_conf="${CONFIG_DIR}/bspwm/bspwmrc"
    if [ -f "$bspwm_conf" ]; then
        if grep -qi "ME6Blocker" "$bspwm_conf"; then
            sed -i '/ME6Blocker/d' "$bspwm_conf"
            log_success "Removed ME6Blocker rules from ~/.config/bspwm/bspwmrc"
        fi
    fi
}

uninstall() {
    banner
    log_info "Uninstalling ME6Blocker..."

    # Remove window manager rules
    remove_wm_rules

    # Remove application directory
    if [ -d "${INSTALL_DIR}" ]; then
        rm -rf "${INSTALL_DIR}"
        log_success "Removed ${INSTALL_DIR}"
    fi

    # Remove binary
    if [ -f "${BIN_DIR}/${BIN_NAME}" ]; then
        rm -f "${BIN_DIR}/${BIN_NAME}"
        log_success "Removed ${BIN_DIR}/${BIN_NAME}"
    fi

    # Remove desktop entry
    if [ -f "${DESKTOP_DIR}/me6blocker.desktop" ]; then
        rm -f "${DESKTOP_DIR}/me6blocker.desktop"
        log_success "Removed ${DESKTOP_DIR}/me6blocker.desktop"
    fi

    # Remove autostart entry
    if [ -f "${AUTOSTART_DIR}/me6blocker.desktop" ]; then
        rm -f "${AUTOSTART_DIR}/me6blocker.desktop"
        log_success "Removed ${AUTOSTART_DIR}/me6blocker.desktop"
    fi

    # Remove icons
    rm -f "${ICON_DIR_256}/me6blocker.png" "${ICON_DIR_DEFAULT}/me6blocker.png" "${PIXMAPS_DIR}/me6blocker.png"
    log_success "Removed icons"

    if command -v update-desktop-database >/dev/null 2>&1; then
        update-desktop-database "${DESKTOP_DIR}" 2>/dev/null || true
    fi

    echo ""
    log_success "ME6Blocker has been completely uninstalled."
    exit 0
}

main() {
    if [ "$1" = "--uninstall" ] || [ "$1" = "-u" ] || [ "$1" = "uninstall" ]; then
        uninstall
    fi

    banner
    check_dependencies
    echo ""
    generate_icons
    install_application
    setup_wm_rules
    echo ""

    # Check if ~/.local/bin is in PATH
    if [[ ":$PATH:" != *":${BIN_DIR}:"* ]]; then
        log_warn "${BIN_DIR} is not in your \$PATH."
        log_info "Add this line to your ~/.bashrc or ~/.zshrc:"
        echo -e "    ${C_BOLD}export PATH=\"\$HOME/.local/bin:\$PATH\"${C_RESET}"
        echo ""
    fi

    echo -e "${C_GREEN}${C_BOLD}=================================================="
    echo "      Installation Completed Successfully!        "
    echo -e "==================================================${C_RESET}"
    echo ""
    echo "You can launch ME6Blocker in multiple ways:"
    echo "  1. App Launcher: Search for 'ME6Blocker' in your application menu (Rofi, Wofi, GNOME, KDE, etc.)"
    echo "  2. Terminal:     Run '${BIN_NAME}'"
    echo "  3. Directly:     python3 ${INSTALL_DIR}/me6blocklinux.py"
    echo ""
    echo "To uninstall at any time, run: ./install.sh --uninstall"
}

main "$@"
