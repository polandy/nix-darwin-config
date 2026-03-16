# nix-darwin management commands

# List all commands
default:
    @just --list

# Build the flake for a host (e.g., just build ambp)
build host:
    darwin-rebuild build --flake .#{{host}}

# Switch to the flake for a host (e.g., just switch amba)
switch host:
    sudo darwin-rebuild switch --flake .#{{host}}

# Format all nix files
fmt:
    nix fmt

# Clean up nix store (garbage collection)
clean:
    sudo nix-collect-garbage -d
