#!/usr/bin/env bash
# Removes matrix-hello and its autostart entries.
set -euo pipefail

DEST="${XDG_DATA_HOME:-$HOME/.local/share}/matrix-hello"
CONFIG="${XDG_CONFIG_HOME:-$HOME/.config}"
APPS="${XDG_DATA_HOME:-$HOME/.local/share}/applications"

for c in "$CONFIG/i3/config" "$HOME/.i3/config" "$CONFIG/sway/config" "$CONFIG/hypr/hyprland.conf"; do
    if [[ -f "$c" ]] && grep -qF "# >>> matrix-hello >>>" "$c"; then
        sed -i '/# >>> matrix-hello >>>/,/# <<< matrix-hello <<</d' "$c"
        echo "Removed autostart from $c"
    fi
done
rm -f "$CONFIG/autostart/matrix-hello.desktop" "$APPS/matrix-terminal.desktop" \
      "$HOME/.local/bin/matrix-hello" "$HOME/.local/bin/matrix-hello-launch" "$HOME/.local/bin/matrix-terminal"
rm -rf "$DEST"
if grep -qs "matrix-hello/matrix.bashrc" ~/.bashrc; then
    echo "Remember to remove the matrix.bashrc line from your ~/.bashrc."
fi
echo "matrix-hello removed. The Matrix no longer has you."
