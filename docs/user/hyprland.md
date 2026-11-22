# Hyprland Desktop Tools

Which tool does what on the Hyprland desktop (Arch Linux). Packages are installed
by metapac (`modules/home-manager/linux/metapac/groups/`), config lives in
`modules/home-manager/linux/wayland/`. Keybindings and autostart are in
`hypr/hyprland.lua` (`Super` = mod key).

## Desktop

| Purpose | Tool | How it runs / key | Config |
|---------|------|-------------------|--------|
| Compositor | [Hyprland](https://hyprland.org/) | Session | `hypr/hyprland.lua` |
| Status bar | [Waybar](https://github.com/Alexays/Waybar) | Autostart, restart with `Super + Shift + W` | `waybar/files/config.hyprland` |
| App launcher | [Rofi](https://github.com/davatorium/rofi) | `Super + D` (run), `Super + Ctrl + D` (combi), `Super + Tab` (windows) | `rofi/` |
| Window switcher | [hyprswitch](https://github.com/H3rmt/hyprswitch) | Autostart daemon, `Alt + Tab` | `hypr/hyprland.lua` |
| Clipboard history | [cliphist](https://github.com/sentriz/cliphist) + `wl-clipboard` | Autostart (`wl-paste --watch`), `Alt + Shift + V` opens searchable history in rofi | `hypr/hyprland.lua` |
| Screenshots | [grimblast](https://github.com/hyprwm/contrib) (grim + slurp) | macOS-style, see [Screenshots](#screenshots) | `hypr/hyprland.lua` |
| Notifications | [dunst](https://dunst-project.org/) | Autostart | `dunst/dunstrc` |
| Idle handling | [hypridle](https://wiki.hypr.land/Hypr-Ecosystem/hypridle/) | Autostart; locks after 5 min, screen off after 10 min | `hypr/hypridle.conf` |
| Screen lock | [hyprlock](https://wiki.hypr.land/Hypr-Ecosystem/hyprlock/) | `Super + Escape` (via `hyprlock-safe` wrapper) | `hypr/hyprlock.conf`, `hypr/hyprlock-safe` |
| Wallpaper | [awww](https://github.com/LGFae/awww) | Autostart daemon; random image from `~/Nextcloud/wallpapers/` on start and reload | `hypr/hyprland.lua` |
| Monitor profiles | [kanshi](https://sr.ht/~emersion/kanshi/) | Autostart; `Super + M` reloads, lid switch toggles clamshell profiles | `kanshi/config` |
| Monitor setup GUI | [nwg-displays](https://github.com/nwg-piotr/nwg-displays) | `XF86Display` | — |
| Volume | `wpctl` (WirePlumber) | Volume keys; `Super + Mute` opens `pavucontrol` | — |
| Media control | `playerctl` | Media keys | — |
| Brightness | [brightnessctl](https://github.com/Hummer12007/brightnessctl) | Brightness keys | — |
| Bluetooth tray | `blueman-applet` | Autostart | — |
| File sync | Nextcloud client | Autostart | — |
| Terminal | [Alacritty](https://alacritty.org/) | `Super + Enter` | `modules/home-manager/linux/alacritty.nix` |
| File manager | Thunar | `Super + E` | — |

## Screenshots

Like macOS, with `Alt` in place of `Cmd`. Screenshots are saved to `~/Pictures/Screenshots/` and
copied to the clipboard; adding `Ctrl` only copies them. The image freezes while selecting, and a
notification follows each capture.

| Key | Captures |
|-----|----------|
| `Alt + Shift + 3` | All screens |
| `Alt + Shift + 4` | Dragged area, or the clicked window |
| `Alt + Shift + 5` | Active window |
| `Alt + Shift + Ctrl + 3/4/5` | Same, clipboard only |
| `Print` | Same as `Alt + Shift + 4` |

## Theming

| Purpose | Tool | Config |
|---------|------|--------|
| GTK theme | adw-gtk-theme (Catppuccin Macchiato) | `linux/gtk.nix` |
| Qt theme | qt6ct | `linux/qt/` |
| Rofi theme | Catppuccin Macchiato | `rofi/catppuccin-macchiato.rasi` |

## Installed but not wired up

These packages are in `wayland.toml` / `base-ui.toml` but have no keybinding or
autostart in Hyprland — candidates for a binding or for removal:

| Tool | Purpose |
|------|---------|
| flameshot | Screenshots (grimblast in use) |
| swaybg, swayidle | Wallpaper / idle (replaced by awww / hypridle) |
| wdisplays, wlr-randr | Monitor setup (nwg-displays / kanshi in use) |
| matugen | Color scheme generation from wallpaper |
| cava | Audio visualizer |
| foot | Terminal |

`playerctl` is bound to the media keys but only installed as a dependency, not
listed in any metapac group.

## Host-specific config

The Hyprland config is shared by all Linux hosts. A host can add to or override it with a
`hosts/<host>/hyprland.lua`, which its `home.nix` deploys as `~/.config/hypr/host.lua`; the shared
`hyprland.lua` loads that file last if it exists. coolermaster uses it for the NVIDIA environment.

## Laptop as frontend for the desktop (Sunshine + Moonlight)

coolermaster runs [Sunshine](https://github.com/LizardByte/Sunshine) (`sunshine-git`, user unit
enabled by `hosts/coolermaster/home.nix`), x1 runs [Moonlight](https://moonlight-stream.org/)
(`moonlight-qt`).

One-time setup:

1. coolermaster: `systemctl --user start app-dev.lizardbyte.app.Sunshine.service`, set credentials in
   the web UI at <https://localhost:47990>. KMS capture needs `sudo setcap cap_sys_admin+p /usr/bin/sunshine`
   (lost on package updates).
2. x1: add coolermaster in Moonlight and enter the PIN in the Sunshine web UI.
3. Moonlight settings: *Capture system keyboard shortcuts* → *in fullscreen*.

Keybindings: in fullscreen Moonlight inhibits the x1's shortcuts, so `Super + …` goes to
coolermaster. `Ctrl + Alt + Shift + Z` releases keyboard and mouse back to x1, `Ctrl + Alt + Shift + Q`
quits the stream. Volume, media, brightness and lid binds are marked `dont_inhibit` and always act
on x1.
