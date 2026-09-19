# ME6Blocker (Linux Edition) 🚫🎮

**ME6Blocker** is an open-source tool designed to block Rocket League Middle East 6 (ME6) high-ping servers on Linux. It dynamically manages `iptables` firewall rules to block high-latency server IP ranges, ensuring smooth, low-ping matchmaking.

---

## ✨ Features

- **One-Click Firewall Toggle**: Instantly enable or disable ME6 server blocking rules via `iptables`.
- **Modern Linux GUI**: Built with PySide6 (Qt6) supporting native Wayland and X11 platforms.
- **Tiling Window Manager Support**: Preconfigured floating, centering, and sizing rules for **Hyprland** (v0.56+), **i3**, **Qtile**, **BSPWM**, and **herbstluftwm**.
- **Seamless Privilege Escalation**: Integrated with `pkexec` (Polkit) for graphical authentication and `sudo` fallback.
- **System Tray Integration**: Minimizes cleanly to the system tray with background protection.
- **Dynamic Cloud IP Updates**: Automatically fetches the latest server IP ranges.
- **Bilingual Interface**: Seamlessly switch between English and Arabic.
- **XDG Desktop Standard**: Full `.desktop` launcher, icon theme integration, and CLI wrapper (`me6blocker`).

---

## 📁 Project Structure

```text
ME6Blocker/
├── assets/
│   ├── logo.ico                    # Windows icon format
│   └── logo.png                    # High-resolution application icon
├── config/
│   └── hyprland-windowrule.conf    # Hyprland v0.56+ floating window rules
├── scripts/
│   ├── apply_window_rules.sh       # Window manager rule installer & detector
│   └── test_window_rules.sh        # Window manager configuration tester
├── install.sh                      # One-click installation & uninstallation script
├── me6blocklinux.py                # Main PySide6 application
├── requirements.txt                # Python dependencies (PySide6, requests)
└── README.md
```

---

## 🚀 Installation

### Automated Install (Recommended)

Clone the repository and run the installer:

```bash
git clone https://github.com/rlyvision/ME6Blocker.git
cd ME6Blocker
chmod +x install.sh
./install.sh
```

The installer will:
1. Check dependencies (`python3`, `PySide6`, `requests`, `iptables`, `pkexec`).
2. Install application files to `~/.local/share/ME6Blocker/`.
3. Install high-resolution application icons to `~/.local/share/icons/hicolor/`.
4. Create the desktop launcher in `~/.local/share/applications/me6blocker.desktop`.
5. Create a CLI command in `~/.local/bin/me6blocker`.
6. Configure floating window rules for Hyprland, i3, Qtile, and BSPWM.

### Launching

- **Application Menu**: Search for `ME6Blocker` in Rofi, Wofi, GNOME, KDE, or your app launcher.
- **Terminal**: Run `me6blocker`.
- **Directly**: Run `python3 ~/.local/share/ME6Blocker/me6blocklinux.py`.

### Uninstallation

To completely remove ME6Blocker, its icons, desktop entries, and binaries:

```bash
./install.sh --uninstall
```

---

## 🪟 Window Manager Configuration

ME6Blocker is designed to open as a compact floating utility (`360x800`).

### Hyprland (v0.56+)

Add the following to your `~/.config/hypr/hyprland.conf`:

```ini
source = ~/.local/share/ME6Blocker/hyprland-windowrule.conf
```

Or manually define the inline rules:

```ini
windowrule = match:class ^(ME6Blocker)$, float on, size 360 800, center on
windowrule = match:title ^(ME6Blocker)$, float on, size 360 800, center on
```

### i3 / Sway

Add to `~/.config/i3/config`:

```ini
for_window [class="^ME6Blocker$"] floating enable, resize set 360 800, move position center
for_window [title="^ME6Blocker$"] floating enable, resize set 360 800, move position center
```

### Qtile

Add to `~/.config/qtile/config.py`:

```python
from libqtile.config import Match

floating_layout.float_rules.extend([
    Match(wm_class="ME6Blocker"),
    Match(title="ME6Blocker")
])
```

---

## 📦 Dependencies

- **Python 3.8+**
- **PySide6** (`python-pyside6` or `pip install PySide6`)
- **requests** (`python-requests` or `pip install requests`)
- **iptables** / **iptables-nft** (for packet filtering)
- **polkit** / **pkexec** (for GUI authentication prompt)

On Arch Linux:
```bash
sudo pacman -S python-pyside6 python-requests iptables polkit
```

On Debian/Ubuntu:
```bash
sudo apt install python3-pyside6.qtwidgets python3-requests iptables policykit-1
```

On Fedora:
```bash
sudo dnf install python3-pyside6 python3-requests iptables polkit
```

---

## 🛡️ How It Works

1. ME6Blocker requests elevated privileges via `pkexec` or `sudo` to access `iptables`.
2. When toggled **ON**, it queries the Middle East server blocklist and inserts `DROP` rules tagged with comment `ME6Blocker` into the `OUTPUT` and `FORWARD` chains.
3. When toggled **OFF** or closed, it safely cleans up all injected firewall rules.

---

## 📄 License
 - Credits to al-fozan for the Windows version
 - Open-source under the MIT License.
## Contact
 - Contact hamzatheboi on discord for any help

