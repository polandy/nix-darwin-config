
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

# Build without activating (macOS only)
build-darwin:
    darwin-rebuild build --flake ".#$(hostname -s)"

fmt:
    nix fmt -- .

clean:
    sudo nix-collect-garbage -d
