# Andy's Nix Config

Personal Nix configuration managing Linux (standalone home-manager) and macOS (nix-darwin) machines.

## Quick Start

* Apply configuration (Linux or macOS): `just switch`
* Upgrade Homebrew formulae and casks (macOS only): `just upgrade`
* Build without activating (macOS only): `just build-darwin`
* Update flake dependencies: `nix flake update`
  (a weekly workflow does this and opens a PR; its commit is signed by GitHub via `peter-evans/create-pull-request` with `sign-commits`, as `main` requires signed commits)

## Primary Tools

| Category | Linux | macOS |
|----------|-------|-------|
| **Terminal** | [Alacritty](https://alacritty.org/) | [Ghostty](https://ghostty.org/) |
| **Window Manager** | [Hyprland](https://hyprland.org/) — see [docs/user/hyprland.md](./docs/user/hyprland.md) | [AeroSpace](https://nikitabobko.github.io/AeroSpace/) — see [docs/user/aerospace.md](./docs/user/aerospace.md) |
| **Status Bar** | [Waybar](https://github.com/Alexays/Waybar) | [Sketchybar](https://felixkratz.github.io/Sketchybar/) — see [docs/user/aerospace.md](./docs/user/aerospace.md) |
| **App Launcher** | [Rofi](https://github.com/davatorium/rofi) | [Raycast](https://www.raycast.com/) |
| **UI Polish** | — | [JankyBorders](https://github.com/FelixKratz/JankyBorders) — see [docs/user/aerospace.md](./docs/user/aerospace.md) |
| **Container Runtime** | Docker | [Colima](https://github.com/abiosoft/colima) (Docker Desktop alternative) |
| **Secrets** | [sops-nix](https://github.com/Mic92/sops-nix) | [sops-nix](https://github.com/Mic92/sops-nix) |

## Package Management Strategy (Linux)

On Arch Linux, three tools share the work:

| Manager | What goes here |
|---------|---------------|
| **home-manager** (this repo) | All configuration, plus portable CLI tools from nixpkgs — via `programs.*` modules (config + package), [`generic/cli-tools.nix`](./modules/home-manager/generic/cli-tools.nix) for CLI tools without a module (shared with macOS; tools not wanted on work machines in [`generic/personal-cli-tools.nix`](./modules/home-manager/generic/personal-cli-tools.nix), imported per host), and `xdg.configFile`/`home.file` for config of apps installed elsewhere |
| **yay/metapac** (config in [`modules/home-manager/linux/metapac/`](./modules/home-manager/linux/metapac/), deployed by home-manager; run `metapac sync` on the host) | Everything that touches the system or needs a GPU — kernel, firmware, bootloader, drivers, system daemons, the Wayland stack, GUI apps, fonts, themes, AUR packages, and utilities that root or remote logins need on the system PATH |
| **[system-manager](https://github.com/numtide/system-manager)** (config in [`modules/system-manager/`](./modules/system-manager/)) | Root-owned files in `/etc` and system services; applied by `just switch` (needs sudo) |

**Rule:** A pure user-level CLI tool comes from nixpkgs: use its `programs.<name>` module if one exists, otherwise add it to `generic/cli-tools.nix`. Anything with systemd/PAM/udev integration, OpenGL/Vulkan, or a pacman hook stays in metapac, with its config files managed by `xdg.configFile` in this repo (writable app state such as databases stays unmanaged in `~/.config`). A package is never listed in both.

This gives all hosts (Arch and macOS) one CLI tool list pinned by `flake.lock`, while system and graphics packages keep Arch's native integration and rolling updates.

This split is permanent for as long as the Linux hosts run Arch. On NixOS, metapac would go away entirely.

## Installation

### Linux (standalone home-manager)

Linux hosts (x1, coolermaster) run Arch Linux with standalone home-manager. System, GUI and AUR packages are managed by yay/metapac; home-manager handles configuration and the portable CLI tools (see [Package Management Strategy](#package-management-strategy-linux)).

1. **Install Nix** using the [Determinate Systems installer](https://github.com/DeterminateSystems/nix-installer):
   ```bash
   curl --proto '=https' --tlsv1.2 -sSf -L https://install.determinate.systems/nix | sh -s -- install
   ```

2. **Clone the repo:**
   ```bash
   git clone https://github.com/polandy/nix-darwin-config.git ~/dev/nix-darwin-config
   cd ~/dev/nix-darwin-config
   ```

3. **First activation** (bootstraps home-manager itself):
   ```bash
   nix run home-manager -- switch --flake .#andy@x1   # or andy@coolermaster
   ```

4. **Subsequent updates** (once home-manager manages itself):
   ```bash
   just switch
   ```

5. **Set up secrets** — copy your age key to `~/.config/sops/age/keys.txt`.

6. **coolermaster only:** create the host-local files (LAN addresses, sandbox user, key and sudoers), see [docs/user/coolermaster-host-local-files.md](./docs/user/coolermaster-host-local-files.md).

### macOS (nix-darwin)

1. **Install Nix** using the [Determinate Systems installer](https://github.com/DeterminateSystems/nix-installer):
   ```bash
   curl --proto '=https' --tlsv1.2 -sSf -L https://install.determinate.systems/nix | sh -s -- install
   ```

2. **Install Homebrew** (required for GUI apps with TCC permissions):
   ```bash
   /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
   ```

3. **Clone the repo and activate:**
   ```bash
   git clone https://github.com/polandy/nix-darwin-config.git ~/dev/nix-darwin-config
   cd ~/dev/nix-darwin-config
   nix run nix-darwin -- switch --flake .#amba   # or .#ambp
   ```

4. **Subsequent updates:**
   ```bash
   just switch
   ```

5. **Set up secrets** — see [docs/dev/sops-nix.md](./docs/dev/sops-nix.md) for age key setup.

---

## Directory Structure

The repository follows a clean, modular structure that separates machine-specific configurations (hosts) from logical groupings of settings (modules).

```text
nix-config/
├── flake.nix               # Entry point: darwinConfigurations + homeConfigurations
├── hosts/                  # Machine-specific configurations
│   ├── x1/                 # ThinkPad X1 (standalone home-manager)
│   ├── coolermaster/       # Desktop (standalone home-manager)
│   ├── amba/               # Personal Mac (nix-darwin)
│   └── ambp/               # Work Mac (nix-darwin)
└── modules/                # Shared configuration modules
    ├── macos/              # macOS-only modules (nix-darwin)
    │   ├── base/           # Foundational settings (users, core packages, basic homebrew)
    │   ├── devops/         # Work-related and devops tools
    │   ├── leisure/        # Personal and hobby applications
    │   ├── fonts.nix       # Font installation
    │   ├── input.nix       # Keyboard and trackpad settings
    │   ├── system.nix      # macOS system defaults
    │   └── ui.nix          # UI defaults (dock, Finder, menu bar, spaces)
    └── home-manager/
        ├── generic/        # Cross-platform HM modules (fish, git, ssh, …)
        ├── linux/          # Linux-only HM modules (packages, WM configs)
        └── macos/          # macOS-only HM modules (aerospace-desktop, syncthing)
```

## Secrets Management

Sensitive values (e.g. Syncthing device IDs) are encrypted with [sops-nix](https://github.com/Mic92/sops-nix) and stored in `secrets/` as YAML files. They are decrypted at activation time using an age private key stored at `~/.config/sops/age/keys.txt` on the local machine — never committed to git.

* Encrypted secrets live in `secrets/*.yaml` (safe to commit — AES256-GCM encrypted)
* Encryption keys and creation rules are declared in `.sops.yaml` at the repo root
* At activation, sops-nix decrypts secrets to files under `/run/user/<uid>/secrets/` (or similar), owned by the relevant user
* [Home Manager](https://github.com/nix-community/home-manager) modules consume secrets via `config.sops.secrets.<name>.path`

For setup instructions and key management details, see [docs/dev/sops-nix.md](./docs/dev/sops-nix.md).

For macOS-specific setup notes (fonts, TCC permissions, Colima, troubleshooting) see [docs/user/macos.md](./docs/user/macos.md).

## License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.
