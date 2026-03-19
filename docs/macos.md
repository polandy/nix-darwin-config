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
