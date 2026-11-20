# Vesper

A simple, configurable bar for [Hyprland](https://hypr.land), built with [Quickshell](https://quickshell.org).

![Vesper's bar with the settings window open](docs/screenshot.png)

Vesper is inspired by noctalia-shell v4: a bar made of widgets you arrange from a settings window, with theming that only affects the bar itself. It deliberately leaves out the extras (wallpaper-based colours, app theming templates, dock, lock screen) to stay small and easy to follow.

## Features

![Close-up of the right side of the bar: clock, tray, volume, settings and session buttons](docs/bar-right.png)

- **Bar** on any edge of the screen, with an exact pixel height, separate content scale, background opacity, and per-monitor settings.
- **Widgets** you can add, remove, reorder and configure from the settings window:

  | Widget | |
  |---|---|
  | Workspaces | Click to switch; optionally only the current monitor's workspaces |
  | Active window | Icon and title of the focused window |
  | Clock | Any Qt date/time format |
  | System tray | App tray icons with their menus |
  | Volume / Microphone | Click to mute, scroll to change |
  | Media | Now playing (MPRIS); play/pause, next, previous |
  | Bluetooth | Status; click to turn on/off |
  | Battery | Hidden on machines without a battery |
  | Power profile | Switch between power saver, balanced and performance |
  | Keyboard layout | Click to switch layout |
  | Lock keys | Caps / Num / Scroll Lock indicators |
  | Custom button | Your own icon, label and commands |
  | Text | Fixed text or a command's output |
  | Spacer, Settings button, Session button | |

- **Session menu**: suspend, log out, reboot, shut down (and lock, if you set a lock command), with keyboard shortcuts and a countdown before destructive actions.
- **Settings window** for everything above. Changes apply immediately and are saved to a plain JSON file, which also reloads live if you edit it by hand.
- **Themes**: Catppuccin Mocha and Latte, Compline and Lauds, Gruvbox Dark, Nord, Rosé Pine and Tokyo Night built in, plus your own.
- **Configurable bar actions**: what scrolling, right-clicking and middle-clicking empty bar space does.
- **IPC** commands for keybinds.

## Requirements

- **Hyprland** with a **Lua config** (`hyprland.lua`). Other compositors and the older `hyprland.conf` format aren't supported.
- **Quickshell** 0.3 or newer.
- **PipeWire** for the volume and microphone widgets.

Optional, for the widgets that use them:

- **BlueZ** (Bluetooth widget)
- **UPower** (Battery widget) and **power-profiles-daemon** (Power profile widget)
- **pavucontrol**, which the volume and microphone widgets open on right click by default (changeable)

## Installation

Quickshell loads configs from `~/.config/quickshell/<name>/`. Clone Vesper there:

```sh
git clone https://github.com/TheyCallMePBJ/vesper.git ~/.config/quickshell/vesper
```

(If you'd rather keep the code elsewhere, clone it anywhere and symlink that folder to `~/.config/quickshell/vesper`.)

Try it out:

```sh
qs -c vesper
```

To start it with Hyprland, add it to your autostart, for example in `autostart.lua`:

```lua
hl.on("hyprland.start", function()
  hl.exec_cmd("qs -c vesper")
end)
```

### Updating

```sh
git -C ~/.config/quickshell/vesper pull
```

Your settings live separately in `~/.config/vesper/`, so updating never touches them. When the settings format changes, Vesper upgrades your file automatically.

## Configuration

Open the settings window with the settings button on the bar, by right-clicking empty bar space (the default action), or with `qs -c vesper ipc call settings toggle`.

Settings are stored in `~/.config/vesper/settings.json`. The file only contains what you've changed; everything else uses the defaults. You can edit it by hand and Vesper picks up changes immediately. If the file has a mistake, Vesper keeps the last working settings and logs a warning.

### Custom themes

Put a JSON file in `~/.config/vesper/themes/`, for example `~/.config/vesper/themes/my-theme.json`:

```json
{
  "name": "My Theme",
  "colors": {
    "background": "#1e1e2e",
    "surface":    "#313244",
    "surfaceAlt": "#45475a",
    "border":     "#585b70",
    "text":       "#cdd6f4",
    "textMuted":  "#7f849c",
    "accent":     "#cba6f7",
    "onAccent":   "#1e1e2e",
    "success":    "#a6e3a1",
    "warning":    "#f9e2af",
    "error":      "#f38ba8"
  }
}
```

It then appears in Appearance → Theme. Any colour you leave out falls back to the default theme. A custom theme with the same file name as a built-in one (e.g. `nord.json`) replaces it. Edits to the selected theme's file apply live.

| Colour | Used for |
|---|---|
| `background` | Bar and panel background |
| `surface` / `surfaceAlt` | Cards, inputs and hover / pressed states |
| `border` | Outlines and dividers |
| `text` / `textMuted` | Main and secondary text (e.g. inactive workspaces) |
| `accent` / `onAccent` | Highlights (focused workspace, toggles) and text drawn on them |
| `success` / `warning` / `error` | Status colours |

### Session commands

Lock, suspend, log out, reboot and shut down run configurable commands (Settings → General). Vesper has no lock screen of its own, so the Lock button only appears once you set a lock command such as `hyprlock`. Logging out exits Hyprland unless you set a command.

## IPC

Call these with `qs -c vesper ipc call <target> <function>`, e.g. in `binds.lua`:

```lua
hl.bind("SUPER + COMMA", hl.dsp.exec_cmd("qs -c vesper ipc call settings toggle"))
hl.bind("XF86AudioRaiseVolume", hl.dsp.exec_cmd("qs -c vesper ipc call volume up"))
```

| Target | Functions |
|---|---|
| `settings` | `toggle`, `open`, `close`, `reload` |
| `session` | `toggle`, `open`, `close` |
| `volume` | `up`, `down`, `toggleMute`, `set <0-100>`, `get` |
| `mic` | `up`, `down`, `toggleMute` |
| `media` | `playPause`, `next`, `previous` |

The volume step is set in Settings → General.

## Credits

- [Tabler Icons](https://tabler.io/icons) by Paweł Kuna (MIT, see `Assets/fonts/tabler-icons-LICENSE.txt`).
- The Compline and Lauds themes use the [Compline](https://github.com/joshuablais/compline) palettes by Joshua Blais.
- Inspired by [noctalia-shell](https://github.com/noctalia-dev) v4.

## License

Vesper is free software, licensed under the [GNU General Public License v3.0](LICENSE) or (at your option) any later version.

The bundled Tabler Icons font keeps its own MIT license.
