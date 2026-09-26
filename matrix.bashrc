# Matrix look for bash: black background, green text, a green prompt and a
# short burst of digital rain when the shell starts.
#
# matrix-terminal uses this file. To make every terminal look like this, add
# this line to the end of your ~/.bashrc:
#     source ~/.local/share/matrix-hello/matrix.bashrc

# When matrix-terminal starts bash with this file, load the user's normal
# config first. The guard stops a loop if ~/.bashrc sources this file too.
if [[ -z "${MATRIX_THEME_LOADED:-}" ]]; then
    MATRIX_THEME_LOADED=1
    [[ -f ~/.bashrc ]] && . ~/.bashrc
fi

_matrix_dir="$(dirname "$(readlink -f "${BASH_SOURCE[0]}")")"
_matrix_name="${MATRIX_HELLO_NAME:-Neo}"

if [[ -t 1 ]]; then
    # Recolour the terminal itself: background, text, cursor (OSC 11/10/12),
    # and the 16-colour palette (OSC 4), all in shades of Matrix green.
    printf '\e]11;#000000\a\e]10;#00ff41\a\e]12;#00ff41\a'
    _i=0
    for _c in 000000 008f11 00ff41 b8ff7a 00af00 39ff14 7cfc00 c8ffc8 \
              005f00 00cc33 5cff7a d4ff9a 00d000 66ff66 aaffaa ffffff; do
        printf '\e]4;%d;#%s\a' "$_i" "$_c"
        _i=$((_i + 1))
    done
    unset _i _c
    printf '\e]0;Matrix\a'

    # Digital rain splash. MATRIX_SPLASH=0 turns it off.
    if [[ "${MATRIX_SPLASH:-2}" != 0 ]] && command -v python3 >/dev/null 2>&1; then
        python3 "$_matrix_dir/matrix_hello.py" --splash "${MATRIX_SPLASH:-2}"
        printf '\e[H\e[2J'
    fi
    printf '\e[1;38;5;46mWake up, %s...\e[0;38;5;34m The Matrix has you.\e[0m\n\n' "$_matrix_name"
fi

# neo@matrix:~/code$
PS1='\[\e[1;38;5;46m\]'"${_matrix_name,,}"'@matrix\[\e[0;38;5;34m\]:\w\[\e[1;38;5;231m\]\$\[\e[0m\] '
unset _matrix_name
