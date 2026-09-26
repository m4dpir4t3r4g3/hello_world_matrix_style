# Shared by matrix-hello-launch and matrix-terminal (source it, don't run it).
# Opens a command in a new terminal window on (almost) any Linux desktop.

# Terminals the current desktop ships with, best first.
_matrix_native_terminals() {
    local desk="${XDG_CURRENT_DESKTOP:-}:${DESKTOP_SESSION:-}"
    case "${desk,,}" in
        *kde*|*plasma*)          echo konsole ;;
        *xfce*|*xubuntu*)        echo xfce4-terminal ;;
        *mate*)                  echo mate-terminal ;;
        *cinnamon*)              echo gnome-terminal xfce4-terminal ;;
        *lxqt*)                  echo qterminal ;;
        *lxde*)                  echo lxterminal ;;
        *budgie*)                echo tilix gnome-terminal ;;
        *gnome*|*ubuntu*|*pop*|*unity*)
                                 echo ptyxis kgx gnome-terminal ;;
    esac
}

# Prints the terminal to use: $MATRIX_HELLO_TERMINAL, then the desktop's own,
# then $TERMINAL, then whatever is installed.
matrix_pick_terminal() {
    local t
    for t in ${MATRIX_HELLO_TERMINAL:-} $(_matrix_native_terminals) ${TERMINAL:-} \
             alacritty kitty foot wezterm konsole gnome-terminal xfce4-terminal \
             ptyxis kgx tilix terminator mate-terminal qterminal lxterminal \
             xterm urxvt xdg-terminal-exec x-terminal-emulator i3-sensible-terminal; do
        if command -v "$t" >/dev/null 2>&1; then
            echo "$t"
            return 0
        fi
    done
    return 1
}

# matrix_open_terminal FULLSCREEN TITLE COMMAND [ARGS...]
# Starts the terminal in the background. FULLSCREEN is 1 or 0.
matrix_open_terminal() {
    local fs="$1" title="$2"
    shift 2
    local term str
    term="$(matrix_pick_terminal)" || {
        echo "matrix-hello: no terminal emulator found (set MATRIX_HELLO_TERMINAL)" >&2
        return 1
    }
    str="$(printf '%q ' "$@")"   # for terminals that take the command as one string

    local argv=()
    _fs() { [[ "$fs" == 1 ]] && argv+=("$@"); return 0; }
    case "${term##*/}" in
        xfce4-terminal)
            argv=(xfce4-terminal --disable-server); _fs --fullscreen
            argv+=(--hide-menubar --hide-toolbar --title="$title" -x "$@") ;;
        gnome-terminal)
            argv=(gnome-terminal); _fs --full-screen
            argv+=(-- "$@") ;;
        konsole)
            argv=(konsole); _fs --fullscreen
            argv+=(--hide-menubar --hide-tabbar -e "$@") ;;
        ptyxis)
            argv=(ptyxis --new-window -x "$str") ;;
        kgx)
            argv=(kgx -- "$@") ;;
        tilix)
            argv=(tilix); _fs --full-screen
            argv+=(-e "$str") ;;
        terminator)
            argv=(terminator); _fs --fullscreen
            argv+=(--borderless -T "$title" -x "$@") ;;
        mate-terminal)
            argv=(mate-terminal); _fs --full-screen
            argv+=(--hide-menubar -t "$title" -x "$@") ;;
        qterminal)
            argv=(qterminal -e "$str") ;;
        lxterminal)
            argv=(lxterminal -t "$title" -e "$str") ;;
        alacritty)
            argv=(alacritty); _fs -o 'window.startup_mode="Fullscreen"'
            argv+=(--title "$title" -e "$@") ;;
        kitty)
            argv=(kitty); _fs --start-as=fullscreen
            argv+=(--title "$title" "$@") ;;
        foot)
            argv=(foot); _fs --fullscreen
            argv+=(--title "$title" "$@") ;;
        wezterm)
            argv=(wezterm start -- "$@") ;;
        xterm)
            argv=(xterm); _fs -fullscreen
            argv+=(-bg black -fg green -fa Monospace -fs 13 -T "$title" -e "$@") ;;
        urxvt)
            argv=(urxvt -bg black -fg green -T "$title" -e "$@") ;;
        xdg-terminal-exec)
            argv=(xdg-terminal-exec "$@") ;;
        *)  # x-terminal-emulator, i3-sensible-terminal and anything else
            argv=("$term" -e "$@") ;;
    esac
    unset -f _fs

    "${argv[@]}" >/dev/null 2>&1 &

    # Tiling window managers: ask them to fullscreen it too, in case the
    # terminal has no fullscreen flag. The window title is set by the script.
    if [[ "$fs" == 1 ]]; then
        local msg=""
        if [[ -n "${SWAYSOCK:-}" ]] && command -v swaymsg >/dev/null 2>&1; then
            msg=swaymsg
        elif command -v i3-msg >/dev/null 2>&1 && i3-msg -t get_version >/dev/null 2>&1; then
            msg=i3-msg
        fi
        if [[ -n "$msg" ]]; then
            local _
            for _ in 1 2 3 4 5 6; do
                sleep 0.4
                "$msg" -q "[title=\"^$title\$\"] fullscreen enable" >/dev/null 2>&1 && break
            done
        fi
    fi
}
