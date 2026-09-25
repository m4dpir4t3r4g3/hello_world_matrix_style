#!/usr/bin/env bash
# Installs matrix-hello and makes it launch every time you log in to i3.
set -euo pipefail

SRC="$(cd "$(dirname "$0")" && pwd)"
DEST="${XDG_DATA_HOME:-$HOME/.local/share}/matrix-hello"
BIN="$HOME/.local/bin"
CONFIG="${XDG_CONFIG_HOME:-$HOME/.config}"
BEGIN="# >>> matrix-hello >>>"
END="# <<< matrix-hello <<<"

command -v python3 >/dev/null || { echo "python3 is required" >&2; exit 1; }

mkdir -p "$DEST" "$BIN"
install -m 755 "$SRC/matrix_hello.py" "$SRC/matrix-hello-launch" "$DEST/"
ln -sf "$DEST/matrix_hello.py" "$BIN/matrix-hello"
ln -sf "$DEST/matrix-hello-launch" "$BIN/matrix-hello-launch"
echo "Installed to $DEST (commands: matrix-hello, matrix-hello-launch)"

# 1) i3: `exec` runs once when i3 starts (not on `i3 restart`).
i3cfg=""
for c in "$CONFIG/i3/config" "$HOME/.i3/config"; do
    [[ -f "$c" ]] && { i3cfg="$c"; break; }
done
if [[ -n "$i3cfg" ]]; then
    if grep -qF "$BEGIN" "$i3cfg"; then
        echo "i3 config already set up: $i3cfg"
    else
        cp "$i3cfg" "$i3cfg.bak-matrix-hello"
        printf '\n%s\nexec --no-startup-id %s\n%s\n' "$BEGIN" "$DEST/matrix-hello-launch" "$END" >> "$i3cfg"
        echo "Added autostart to $i3cfg (backup: $i3cfg.bak-matrix-hello)"
    fi
else
    echo "No i3 config found; add this line to it yourself:"
    echo "    exec --no-startup-id $DEST/matrix-hello-launch"
fi

# 2) XDG autostart, for the Xubuntu/XFCE session (e.g. XFCE with i3 as the
#    window manager). The launcher's lock stops a double launch.
mkdir -p "$CONFIG/autostart"
cat > "$CONFIG/autostart/matrix-hello.desktop" <<DESKTOP
[Desktop Entry]
Type=Application
Name=Matrix Hello
Comment=Wake up, Neo...
Exec=$DEST/matrix-hello-launch
Terminal=false
X-GNOME-Autostart-enabled=true
DESKTOP
echo "Added $CONFIG/autostart/matrix-hello.desktop"

echo
echo "Try it now:  matrix-hello-launch --force    (or just: matrix-hello)"
echo "It will run automatically on your next login."
