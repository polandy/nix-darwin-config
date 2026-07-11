# nix-darwin / home-manager management commands

# Map macOS hostname -> flake config name (darwin configs aren't named after the raw hostname)
darwin_host := `
  case "$(hostname -s)" in
    Andys-MacBook-Air) echo ambp ;;
    Andys-MacBook-Air-2) echo amba ;;
    *) echo "" ;;
  esac`

# List all commands
default:
    @just --list

# Switch to the appropriate configuration for the current host (macOS or Linux)
switch:
    #!/usr/bin/env bash
    set -euo pipefail
    if [[ "$(uname)" == "Darwin" ]]; then
      flake_host="{{darwin_host}}"
      if [[ -z "$flake_host" ]]; then
        echo "error: no flake config mapped for host '$(hostname -s)'"
        exit 1
      fi
      sudo darwin-rebuild switch --flake ".#$flake_host"
    else
      home-manager switch --flake ".#andy@$(hostname -s)"
    fi

# Build without activating — macOS only (darwin-rebuild has no Linux equivalent)
build-darwin:
    #!/usr/bin/env bash
    set -euo pipefail
    flake_host="{{darwin_host}}"
    if [[ -z "$flake_host" ]]; then
      echo "error: no flake config mapped for host '$(hostname -s)'"
      exit 1
    fi
    darwin-rebuild build --flake ".#$flake_host"

# Format all nix files
fmt:
    nix fmt

# Clean up nix store (garbage collection)
clean:
    sudo nix-collect-garbage -d
