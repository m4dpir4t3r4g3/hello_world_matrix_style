#!/usr/bin/env bash
# Installs matrix-hello on Linux and makes it launch every time you log in.
#
#   ./install.sh                  install + autostart on login
#   ./install.sh --no-autostart   install the commands only
set -euo pipefail

SRC="$(cd "$(dirname "$0")" && pwd)"
DEST="${XDG_DATA_HOME:-$HOME/.local/share}/matrix-hello"
BIN="$HOME/.local/bin"
CONFIG="${XDG_CONFIG_HOME:-$HOME/.config}"
APPS="${XDG_DATA_HOME:-$HOME/.local/share}/applications"
BEGIN="# >>> matrix-hello >>>"
END="# <<< matrix-hello <<<"
LAUNCH="$DEST/matrix-hello-launch"

autostart=1
[[ "${1:-}" == "--no-autostart" ]] && autostart=0

command -v python3 >/dev/null || { echo "python3 is required (install it with your package manager)" >&2; exit 1; }
python3 -c "import curses" 2>/dev/null || { echo "python3 is missing the curses module (e.g. install python3-curses)" >&2; exit 1; }

mkdir -p "$DEST" "$BIN" "$APPS"
install -m 755 "$SRC/matrix_hello.py" "$SRC/matrix-hello-launch" "$SRC/matrix-terminal" "$DEST/"
install -m 644 "$SRC/term.sh" "$SRC/matrix.bashrc" "$DEST/"
ln -sf "$DEST/matrix_hello.py" "$BIN/matrix-hello"
ln -sf "$DEST/matrix-hello-launch" "$BIN/matrix-hello-launch"
ln -sf "$DEST/matrix-terminal" "$BIN/matrix-terminal"
echo "Installed to $DEST"
echo "Commands: matrix-hello, matrix-hello-launch, matrix-terminal"

# "Matrix Terminal" in the applications menu
cat > "$APPS/matrix-terminal.desktop" <<DESKTOP
[Desktop Entry]
Type=Application
Name=Matrix Terminal
Comment=Follow the white rabbit
Exec=$DEST/matrix-terminal
Icon=utilities-terminal
Terminal=false
Categories=System;TerminalEmulator;
DESKTOP
echo "Added Matrix Terminal to your applications menu"

if [[ $autostart == 0 ]]; then
    exit 0
fi

# add_block FILE LINE: append LINE between markers, once, after a backup.
add_block() {
    local file="$1" line="$2"
    [[ -f "$file" ]] || return 0
    if grep -qF "$BEGIN" "$file"; then
        echo "Already set up: $file"
    else
        cp "$file" "$file.bak-matrix-hello"
        printf '\n%s\n%s\n%s\n' "$BEGIN" "$line" "$END" >> "$file"
        echo "Added autostart to $file (backup: $file.bak-matrix-hello)"
    fi
}

# 1) Desktop environments (GNOME, KDE Plasma, XFCE, Cinnamon, MATE, LXQt,
#    Budgie, ...) all read XDG autostart entries.
mkdir -p "$CONFIG/autostart"
cat > "$CONFIG/autostart/matrix-hello.desktop" <<DESKTOP
[Desktop Entry]
Type=Application
Name=Matrix Hello
Comment=Wake up, Neo...
Exec=$LAUNCH
Terminal=false
X-GNOME-Autostart-enabled=true
DESKTOP
echo "Added $CONFIG/autostart/matrix-hello.desktop"

# 2) Tiling window managers don't read XDG autostart, so add them to their
#    config. The launcher's lock stops a double launch if both fire.
i3cfg="$CONFIG/i3/config"
[[ -f "$i3cfg" ]] || i3cfg="$HOME/.i3/config"
add_block "$i3cfg" "exec --no-startup-id $LAUNCH"
add_block "$CONFIG/sway/config" "exec $LAUNCH"
add_block "$CONFIG/hypr/hyprland.conf" "exec-once = $LAUNCH"

echo
echo "Using another window manager (bspwm, awesome, openbox, dwm...)?"
echo "Add this to its startup file:  $LAUNCH &"
echo
case ":$PATH:" in
    *":$BIN:"*) ;;
    *) echo "Note: $BIN is not on your PATH yet; log out and back in, or use the full paths." ;;
esac
echo "Try it now:  matrix-hello-launch --force    or    matrix-terminal"
echo "It will run automatically on your next login."
