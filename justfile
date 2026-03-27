# nix-darwin management commands

# List all commands
default:
    @just --list

# Switch to the appropriate configuration for the current host (macOS or Linux)
switch:
    #!/usr/bin/env bash
    if [[ "$(uname)" == "Darwin" ]]; then
      declare -A host_map=(
        ["Andys-MacBook-Air"]="ambp"
        ["Andys-MacBook-Air-2"]="amba"
      )
      hostname=$(hostname -s)
      flake_host="${host_map[$hostname]}"
      if [[ -z "$flake_host" ]]; then
        echo "error: no flake config mapped for host '$hostname'"
        exit 1
      fi
      sudo darwin-rebuild switch --flake ".#$flake_host"
    else
      home-manager switch --flake .#andy@$(hostname)
    fi

# Build without activating — macOS only (darwin-rebuild has no Linux equivalent)
build-darwin:
    darwin-rebuild build --flake .#$(hostname -s)

# Format all nix files
fmt:
    nix fmt

# Clean up nix store (garbage collection)
clean:
    sudo nix-collect-garbage -d

# Reload sketchybar config (copies from repo then reloads)
reload-bar:
    rm -rf ~/.config/sketchybar && \
    cp -r ~/nix-darwin-config/modules/home-manager/sketchybar_config/. ~/.config/sketchybar/ && \
    sketchybar --reload
