# macOS Setup Notes

## Manual Font Installation (Required)

Due to licensing restrictions, Apple's proprietary fonts cannot be automatically installed via Nix. You **must** manually download and install them for the Sketchybar UI to render correctly:

1. **SF Pro Fonts:** [Download from Apple Developer](https://developer.apple.com/fonts/) (Install the `SF Pro` family).
2. **SF Symbols:** [Download SF Symbols 6](https://developer.apple.com/sf-symbols/) (Required for system icons like CPU, RAM, and Battery).

*Note: The `sketchybar-app-font` is handled automatically via Homebrew Cask once the requirements above are met.*

## GUI App Permissions (TCC)

macOS grants app permissions (e.g. Accessibility, Full Disk Access) by binary path or bundle ID.
Nix packages install to `/nix/store/<hash>-<name>/`, and the hash changes with every update —
causing macOS to revoke permissions and prompt for re-authorization after each `darwin-rebuild switch`.

To avoid this, GUI apps that require system permissions are installed via [Homebrew Cask](https://github.com/Homebrew/homebrew-cask) instead
of as Nix packages. Homebrew Cask installs to `/Applications/<App>.app` with a stable bundle ID,
so permissions persist across updates.

### The terminal needs App Management

`darwin-rebuild` writes to `/Applications/Nix Apps`, which requires the `App Management` permission
(`kTCCServiceSystemPolicyAppBundles`). macOS attributes that request to the *terminal emulator the
command runs in*, not to `darwin-rebuild` itself. Without it the rebuild aborts before activation:

```
error: permission denied when trying to update apps, aborting activation
```

This is why **Alacritty is a Homebrew cask** and not a nixpkgs package, even though it builds fine for
aarch64-darwin. As a Nix package it runs from `/nix/store/<hash>-alacritty-<version>/bin/alacritty`,
so the grant would be revoked by the very next `alacritty` update and every rebuild after that would
fail until the permission is re-granted. The cask keeps it at `/Applications/Alacritty.app`.

Home Manager still owns the configuration (`modules/home-manager/generic/alacritty.nix`); it installs
a stub package so that `~/.config/alacritty/alacritty.toml` is generated without providing the binary.
Linux uses the same stub, there because Nix-packaged alacritty cannot find host GPU drivers on
non-NixOS.

Grant the permission under System Settings > Privacy & Security > App Management. If the entry points
at a `/nix/store/...` path from an earlier setup, remove it — it is tied to a build that no longer exists.

The related problem of macOS *login items* storing store paths is described in
[aerospace.md](aerospace.md#startup).

## Colima Container Runtime

[Colima](https://github.com/abiosoft/colima) provides a seamless way to run Docker workloads in a virtualized environment using Apple's Virtualization framework.

Start a Colima instance with optimized settings for Apple Silicon:

* `colima start --vm-type=vz --vz-rosetta --cpu 2 --memory 2 --disk 20`
  * `--vm-type=vz`: Use Apple's Virtualization framework instead of the default QEMU.
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
