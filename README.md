# Andy's Nix Darwin Setup

This is a personal [nix-darwin](https://github.com/LnL7/nix-darwin) configuration for managing macOS systems, optimized for **Apple Silicon (M1/M2/M3)**.

## Quick Start

* Apply system configuration: `darwin-rebuild switch --flake .#"ambp"`
* Build configuration to test: `darwin-rebuild build --flake .#"ambp"`
* Update flake dependencies: `nix flake update`

## Primary Tools

* **Terminal Emulator:** [Alacritty](https://alacritty.org/) (launched via AeroSpace with `Option + Enter`).
* **Window Manager:** [AeroSpace](https://nikitabobko.github.io/AeroSpace/) (i3-like tiling for macOS).
* **Status Bar:** [Sketchybar](https://felixkratz.github.io/Sketchybar/) (highly customizable macOS bar).
* **UI Polish:** [JankyBorders](https://github.com/FelixKratz/JankyBorders) (active window borders).
* **Container Runtime:** [Colima](https://github.com/abiosoft/colima) (Docker Desktop alternative).
* **Secrets:** [sops-nix](https://github.com/Mic92/sops-nix) (age-encrypted secrets).

## First-Time Setup

1. **Install Nix:** Use the [Determinate Systems installer](https://github.com/DeterminateSystems/nix-installer) (recommended).
2. **Install Homebrew:** [Brew](https://brew.sh/) is required for GUI apps with TCC permissions.
3. **Clone and Switch:**

   ```bash
   git clone https://github.com/andy/nix-darwin-config.git ~/nix-darwin-config
   cd ~/nix-darwin-config
   nix run nix-darwin -- switch --flake .#amba
   ```

## Directory Structure

The repository follows a clean, modular structure that separates machine-specific configurations (hosts) from logical groupings of settings (modules).

```text
nix-darwin/
├── flake.nix               # Main entry point defining the configurations for all machines
├── hosts/                  # Machine-specific configurations
│   ├── amba/               # Configuration for personal Mac
│   └── ambp/               # Configuration for work Mac
└── modules/                # Shared configuration modules
    ├── base/               # Foundational settings (users, core packages, basic homebrew)
    ├── devops/             # Work-related and devops tools
    ├── leisure/            # Personal and hobby applications
    ├── macos/              # macOS system settings (UI, hardware, system defaults)
    └── home-manager/       # Shared Home Manager submodules (e.g., syncthing.nix)
```

## Secrets Management

Sensitive values (e.g. Syncthing device IDs) are encrypted with [sops-nix](https://github.com/Mic92/sops-nix) and stored in `secrets/` as YAML files. They are decrypted at `darwin-rebuild switch` time using an age private key stored at `~/.config/sops/age/keys.txt` on the local machine — never committed to git.

* Encrypted secrets live in `secrets/*.yaml` (safe to commit — AES256-GCM encrypted)
* Encryption keys and creation rules are declared in `.sops.yaml` at the repo root
* At activation, sops-nix decrypts secrets to files under `/run/user/<uid>/secrets/` (or similar), owned by the relevant user
* [Home Manager](https://github.com/nix-community/home-manager) modules consume secrets via `config.sops.secrets.<name>.path`

For setup instructions and key management details, see [docs/sops-nix.md](./docs/sops-nix.md).

## GUI App Permissions (TCC)

macOS grants app permissions (e.g. Accessibility, Full Disk Access) by binary path or bundle ID.
Nix packages install to `/nix/store/<hash>-<name>/`, and the hash changes with every update —
causing macOS to revoke permissions and prompt for re-authorization after each `darwin-rebuild switch`.

To avoid this, GUI apps that require system permissions are installed via [Homebrew Cask](https://github.com/Homebrew/homebrew-cask) instead
of as Nix packages. Homebrew Cask installs to `/Applications/<App>.app` with a stable bundle ID,
so permissions persist across updates.

## AeroSpace Startup Configuration

AeroSpace is configured to start automatically as a user-level service via [Home Manager](https://github.com/nix-community/home-manager) (`launchd.agents.aerospace.enable = true`) rather than its native `start-at-login` setting in `aerospace.toml`.

This is intentional: the native `start-at-login` mechanism registers an absolute application path in macOS Login Items. Because Nix updates often change this path in the `/nix/store`, the native registration would break after every update. Using the Home Manager `launchd` service ensures the agent always points to the current, correct version of AeroSpace provided by Nix.

## Setup Colima Container Runtime

[Colima](https://github.com/abiosoft/colima) provides a seamless way to run Docker workloads in a virtualized environment using Apple’s Virtualization framework.

Start a Colima instance with optimized settings for Apple Silicon:

* `colima start --vm-type=vz --vz-rosetta --cpu 2 --memory 2 --disk 20`
  * `--vm-type=vz`: Use Apple’s Virtualization framework instead of the default QEMU.
  * `--vz-rosetta`: Enables Rosetta 2 translation for x86/AMD64 container images on Apple Silicon.
  * `--cpu 2`: Allocates 2 CPU cores to the virtual machine.
  * `--memory 2`: Allocates 2 GB of RAM to the virtual machine.
  * `--disk 20`: Allocates 20 GB of disk space.

## Troubleshooting

### Alacritty: "Apple could not verify..." Error

If you get a security warning when opening Alacritty (e.g., via `Option + Enter`), it's likely because macOS has quarantined the application. Run the following command to remove the quarantine attribute:

```bash
sudo xattr -rd com.apple.quarantine /Applications/Alacritty.app
```

## License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.
