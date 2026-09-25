#!/usr/bin/env bash
# Removes matrix-hello and its autostart entries.
set -euo pipefail

DEST="${XDG_DATA_HOME:-$HOME/.local/share}/matrix-hello"
CONFIG="${XDG_CONFIG_HOME:-$HOME/.config}"

for c in "$CONFIG/i3/config" "$HOME/.i3/config"; do
    if [[ -f "$c" ]] && grep -qF "# >>> matrix-hello >>>" "$c"; then
        sed -i '/# >>> matrix-hello >>>/,/# <<< matrix-hello <<</d' "$c"
        echo "Removed autostart from $c"
    fi
done
rm -f "$CONFIG/autostart/matrix-hello.desktop" "$HOME/.local/bin/matrix-hello" "$HOME/.local/bin/matrix-hello-launch"
rm -rf "$DEST"
echo "matrix-hello removed. The Matrix no longer has you."
