# nix-darwin / home-manager management commands

# List all commands
default:
    @just --list

# Switch to the appropriate configuration for the current host (macOS or Linux)
switch:
    #!/usr/bin/env bash
    set -euo pipefail
    if [[ "$(uname)" == "Darwin" ]]; then
      # networking.hostName is set to the flake config name in hosts/<host>/default.nix.
      # On a fresh machine (hostname not yet applied) use: darwin-rebuild switch --flake .#<host>
      sudo darwin-rebuild switch --flake ".#$(hostname -s)"
    else
      home-manager switch --flake ".#andy@$(hostname -s)"
    fi

# Build without activating — macOS only (darwin-rebuild has no Linux equivalent)
build-darwin:
    darwin-rebuild build --flake ".#$(hostname -s)"

# Format all nix files
fmt:
    nix fmt

# Clean up nix store (garbage collection)
clean:
    sudo nix-collect-garbage -d
