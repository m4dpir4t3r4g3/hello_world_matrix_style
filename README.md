# matrix-hello

A Matrix-inspired "Hello, World" that greets you every time you log in to i3.

```
  Wake up, Neo...
  The Matrix has you...
  Follow the white rabbit.        (\(\
                                  ( -.-)   <- hops across the screen
                                  o_(")(")
  Knock, knock, Neo.
```

Then digital rain in green katakana fills the screen and **H E L L O ,  W O R L D .**
decodes out of it: *"Welcome to the real world, Neo."*

It needs only `python3`, which Xubuntu ships with, and runs in the curses terminal library.

## Install (Xubuntu + i3)

```bash
git clone <this repo> && cd hello_world_matrix_style
./install.sh
matrix-hello-launch --force      # try it right now
```

`install.sh` does three things:

1. Copies the files to `~/.local/share/matrix-hello` and links the
   `matrix-hello` and `matrix-hello-launch` commands in `~/.local/bin`.
2. Adds `exec --no-startup-id .../matrix-hello-launch` to your i3 config
   (`~/.config/i3/config` or `~/.i3/config`) and saves a backup first.
3. Adds `~/.config/autostart/matrix-hello.desktop` so it also works in an XFCE
   session that uses i3 as its window manager.

The launcher runs only once per login, so it won't show up twice if both
autostarts fire, and it won't rerun on `i3 restart`. It waits 2 seconds
for the desktop to settle, then opens a fullscreen terminal. It tries
xfce4-terminal first, then alacritty, kitty, gnome-terminal, xterm, and
i3-sensible-terminal. It also asks i3 to make the window fullscreen.

Uninstall with `./uninstall.sh`.

## Controls

| Key       | Action                                           |
|-----------|--------------------------------------------------|
| any key   | skip to the next scene (exits on the last scene) |
| `q`/`Esc` | exit immediately                                 |

After the final message appears, it closes by itself after 60 seconds.

## Customise

```bash
matrix-hello --name Trinity            # "Wake up, Trinity..."
matrix-hello --message "Hello, $USER"  # change the decoded message
matrix-hello --no-intro                # go straight to the rain
matrix-hello --rain-seconds 10 --timeout 0   # more rain, stay until a key
matrix-hello --ascii                   # font has no katakana? use ASCII
```

For the autostart version, set env vars in your i3 config line, for example
`exec --no-startup-id env MATRIX_HELLO_NAME=Trinity MATRIX_HELLO_DELAY=4 ~/.local/share/matrix-hello/matrix-hello-launch`.
You can also add script flags after the launcher path.

| Variable                | Default   | Meaning                         |
|-------------------------|-----------|---------------------------------|
| `MATRIX_HELLO_NAME`     | `Neo`     | who to wake up                  |
| `MATRIX_HELLO_DELAY`    | `2`       | seconds to wait after login     |
| `MATRIX_HELLO_TERMINAL` | auto      | e.g. `alacritty`, `xterm`       |

If the katakana shows up as boxes, install a font that has it
(`sudo apt install fonts-noto-cjk`) or use `--ascii`.
