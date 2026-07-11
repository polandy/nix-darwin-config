# Troubleshooting

## Hyprland session fails to start (SDDM exits immediately)

**Symptom:** After login, the Hyprland session closes immediately and you are dropped back to a TTY.

**Cause:** The Arch `hyprland` package includes a `start-hyprland` wrapper binary that detects whether Hyprland was installed via Nix. If a Nix-installed Hyprland is found in `$PATH` (e.g. via home-manager) and `nixGL` is not installed, it refuses to start with:

```
ERR from start-hyprland]: Nix environment check failed:
Hyprland was installed using Nix, but you're not on NixOS. This requires nixGL to be installed as well.
```

**Fix:** Do not install `hyprland`, `hyprlock`, or `hypridle` via home-manager on this host. They are managed as system packages via metapac (`~/.dotfiles/config/metapac/groups/generic/wayland.toml`). Home-manager only manages their config files.
