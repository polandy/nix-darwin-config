# Troubleshooting

## Atuin daemon not running

**Error:**
```
Error: failed to connect to local atuin daemon at /Users/andy/.local/share/atuin/daemon.sock. Is it running?

Caused by:
   0: transport error
   1: Connection refused (os error 61)
   2: Connection refused (os error 61)
```

**Cause:** The atuin daemon left a stale socket file when it previously crashed or was killed uncleanly. The launchd service then fails to restart because the socket path is already in use.

**Logs:**
```sh
# View recent logs
/usr/bin/log show --predicate 'processImagePath contains "atuin"' --last 1h

# Stream logs live
/usr/bin/log stream --predicate 'processImagePath contains "atuin"'
```

**Fix:**
```sh
rm ~/.local/share/atuin/daemon.sock
launchctl kickstart -k gui/$(id -u)/org.nix-community.home.atuin-daemon
```

## Hyprland session fails to start (SDDM exits immediately)

**Symptom:** After login, the Hyprland session closes immediately and you are dropped back to a TTY.

**Cause:** The Arch `hyprland` package includes a `start-hyprland` wrapper binary that detects whether Hyprland was installed via Nix. If a Nix-installed Hyprland is found in `$PATH` (e.g. via home-manager) and `nixGL` is not installed, it refuses to start with:

```
ERR from start-hyprland]: Nix environment check failed:
Hyprland was installed using Nix, but you're not on NixOS. This requires nixGL to be installed as well.
```

**Fix:** Do not install `hyprland`, `hyprlock`, or `hypridle` via home-manager on this host. They are managed as system packages via metapac (`~/.dotfiles/config/metapac/groups/generic/wayland.toml`). Home-manager only manages their config files.
