
default:
    @just --list

# Switch to the current host's configuration
switch:
    #!/usr/bin/env bash
    set -euo pipefail
    if [[ "$(uname)" == "Darwin" ]]; then
      sudo darwin-rebuild switch --flake ".#$(hostname -s)"
    else
      nix run --inputs-from . system-manager -- switch --flake ".#$(hostname -s)" --sudo
      home-manager switch --flake ".#andy@$(hostname -s)"
    fi

# Upgrade Homebrew formulae and casks; `just switch` installs but never upgrades them (macOS only)
upgrade:
    brew update
    brew upgrade

# Build without activating (macOS only)
build-darwin:
    darwin-rebuild build --flake ".#$(hostname -s)"

fmt:
    nix fmt -- .

# Delete generations older than 14 days and collect garbage (keeps recent rollbacks)
clean:
    sudo nix-collect-garbage --delete-older-than 14d
