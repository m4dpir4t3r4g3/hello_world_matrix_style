# matrix-hello

A Matrix-inspired "Hello, World" that greets you every time you log in, on
Linux (any distro, any desktop) and Windows 10/11. It also comes with a
**Matrix Terminal**: a green-on-black shell that opens with digital rain.

![matrix-hello demo](docs/demo.gif)

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

## Install on Linux

```bash
git clone https://github.com/m4dpir4t3r4g3/hello_world_matrix_style.git
cd hello_world_matrix_style
./install.sh
matrix-hello-launch --force      # try it right now
```

You need `python3`, which almost every distro ships with. `install.sh`:

1. Copies the files to `~/.local/share/matrix-hello` and adds the
   `matrix-hello`, `matrix-hello-launch` and `matrix-terminal` commands to
   `~/.local/bin`.
2. Adds **Matrix Terminal** to your applications menu.
3. Sets up autostart:
   - **GNOME, KDE Plasma, XFCE, Cinnamon, MATE, LXQt, Budgie** and other
     desktops: `~/.config/autostart/matrix-hello.desktop`
   - **i3, sway, Hyprland**: a line in their config file, with a backup made
     first
   - Other window managers (bspwm, awesome, openbox, ...): the installer
     prints the line to add to your startup file.

Use `./install.sh --no-autostart` if you only want the commands. Uninstall
with `./uninstall.sh`.

It runs only once per login, even if several autostart methods fire. It opens
fullscreen in your desktop's own terminal (Konsole on KDE, GNOME Terminal or
Ptyxis on GNOME, xfce4-terminal on XFCE, ...). If there isn't one, it tries
alacritty, kitty, foot, wezterm, tilix, terminator, xterm and others. Set
`MATRIX_HELLO_TERMINAL` to choose one yourself.

## Install on Windows 10/11

1. Install Python 3 if you don't have it: `winget install -e --id Python.Python.3.12`
   (or from [python.org](https://www.python.org/downloads/)).
2. Download this repo (**Code → Download ZIP**) and unzip it.
3. Double-click **`windows\install.cmd`**.

The installer:

- installs `windows-curses`, which Python on Windows needs for this
- runs matrix-hello fullscreen in Windows Terminal every time you log in (a
  shortcut in your Startup folder)
- adds **Matrix PowerShell** and **Matrix CMD** profiles to Windows Terminal
- adds **Matrix Terminal** to the Start menu

Uninstall by double-clicking `windows\uninstall.cmd`.

## Matrix Terminal

![Matrix Terminal demo](docs/matrix-terminal.gif)

A short burst of digital rain, then a shell with a black background, green
text and a `neo@matrix` prompt.

- **Linux:** open *Matrix Terminal* from your applications menu, or run
  `matrix-terminal`. Run `matrix-terminal --here` to turn the terminal you're
  already in into one. To make *every* terminal look like this, add this line
  to the end of your `~/.bashrc`:
  `source ~/.local/share/matrix-hello/matrix.bashrc`
- **Windows:** open *Matrix Terminal* from the Start menu, or pick *Matrix
  PowerShell* / *Matrix CMD* from the ⌄ menu in Windows Terminal. You can
  make one your default in Windows Terminal's settings (*Startup → Default
  profile*).

On Linux, the colours are set with standard escape codes that almost all
terminals support. Set `MATRIX_SPLASH=0` to skip the rain, or
`MATRIX_SPLASH=5` for more.

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
matrix-hello --splash 5                # just 5 seconds of rain
matrix-hello --ascii                   # font has no katakana? use ASCII
```

These environment variables work for the autostart, the Matrix Terminal and
the Windows version:

| Variable                | Default   | Meaning                             |
|-------------------------|-----------|-------------------------------------|
| `MATRIX_HELLO_NAME`     | `Neo`     | who to wake up (and the prompt name) |
| `MATRIX_HELLO_DELAY`    | `2` (Linux), `3` (Windows) | seconds to wait after login |
| `MATRIX_HELLO_TERMINAL` | auto      | Linux only, e.g. `konsole`, `alacritty` |
| `MATRIX_SPLASH`         | `2`       | seconds of rain when Matrix Terminal opens; `0` for none |

Set them in `~/.profile` on Linux, or for your Windows user with
`setx MATRIX_HELLO_NAME Trinity`.

If the katakana shows up as boxes, install a font that has it (for example
`fonts-noto-cjk` on Debian/Ubuntu, `google-noto-sans-cjk-fonts` on Fedora,
`noto-fonts-cjk` on Arch), or use `--ascii`.

## License

[MIT](LICENSE)
