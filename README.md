# Andy's Nix Config

Personal Nix configuration managing macOS (nix-darwin) and Linux (standalone home-manager) machines.

## Quick Start

* Apply configuration (macOS or Linux): `just switch`
* Build without activating (macOS only): `just build-darwin`
* Update flake dependencies: `nix flake update`

## Primary Tools

* **Terminal Emulator:** [Alacritty](https://alacritty.org/) (launched via AeroSpace with `Option + Enter`).
* **Window Manager:** [AeroSpace](https://nikitabobko.github.io/AeroSpace/) (i3-like tiling for macOS) — see [docs/aerospace.md](./docs/aerospace.md).
* **Status Bar:** [Sketchybar](https://felixkratz.github.io/Sketchybar/) (highly customizable macOS bar) — see [docs/aerospace.md](./docs/aerospace.md).
* **UI Polish:** [JankyBorders](https://github.com/FelixKratz/JankyBorders) (active window borders) — see [docs/aerospace.md](./docs/aerospace.md).
* **Container Runtime:** [Colima](https://github.com/abiosoft/colima) (Docker Desktop alternative).
* **Secrets:** [sops-nix](https://github.com/Mic92/sops-nix) (age-encrypted secrets).

## Package Management Strategy (Linux)

On Arch Linux, two package managers coexist:

| Manager | What goes here |
|---------|---------------|
| **home-manager** (this repo) | User-level tools and apps available in nixpkgs, dotfile/config management |
| **yay/metapac** ([dotfiles repo](https://github.com/polandy/dotfiles)) | AUR packages, system daemons and drivers, anything requiring pacman hooks or systemd system units |

**Rule of thumb:** if it's in nixpkgs and user-level, it belongs here. If it's AUR (e.g. `-bin`, `-git` suffixes) or touches the system (kernel, display manager, portals, bluetooth), it stays in yay.

This split is permanent for as long as the Linux hosts run Arch. On NixOS, metapac would go away entirely.

## Installation

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

5. **Set up secrets** — see [docs/sops-nix.md](./docs/sops-nix.md) for age key setup.

### Linux (standalone home-manager)

Linux hosts (x1, coolermaster) run Arch Linux with standalone home-manager. System packages are still managed by yay/metapac; home-manager handles dotfiles and user packages.

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

---

## Directory Structure

The repository follows a clean, modular structure that separates machine-specific configurations (hosts) from logical groupings of settings (modules).

```text
nix-config/
├── flake.nix               # Entry point: darwinConfigurations + homeConfigurations
├── hosts/                  # Machine-specific configurations
│   ├── amba/               # Personal Mac (nix-darwin)
│   ├── ambp/               # Work Mac (nix-darwin)
│   ├── x1/                 # ThinkPad X1 (standalone home-manager)
│   └── coolermaster/       # Desktop (standalone home-manager)
└── modules/                # Shared configuration modules
    ├── base/               # Foundational settings (users, core packages, basic homebrew)
    ├── devops/             # Work-related and devops tools
    ├── leisure/            # Personal and hobby applications
    ├── macos/              # macOS system settings (UI, hardware, system defaults)
    └── home-manager/
        ├── generic/        # Cross-platform HM modules (fish, git, ssh, syncthing)
        ├── macos/          # macOS-only HM modules (aerospace-desktop)
        └── linux/          # Linux-only HM modules (packages, WM configs)
```

## Secrets Management

Sensitive values (e.g. Syncthing device IDs) are encrypted with [sops-nix](https://github.com/Mic92/sops-nix) and stored in `secrets/` as YAML files. They are decrypted at activation time using an age private key stored at `~/.config/sops/age/keys.txt` on the local machine — never committed to git.

* Encrypted secrets live in `secrets/*.yaml` (safe to commit — AES256-GCM encrypted)
* Encryption keys and creation rules are declared in `.sops.yaml` at the repo root
* At activation, sops-nix decrypts secrets to files under `/run/user/<uid>/secrets/` (or similar), owned by the relevant user
* [Home Manager](https://github.com/nix-community/home-manager) modules consume secrets via `config.sops.secrets.<name>.path`

For setup instructions and key management details, see [docs/sops-nix.md](./docs/sops-nix.md).

For macOS-specific setup notes (fonts, TCC permissions, Colima, troubleshooting) see [docs/macos.md](./docs/macos.md).

## License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.
