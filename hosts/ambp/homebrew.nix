{ ... }:

{
  # Host-specific casks, merged with the shared lists in modules/macos/{base,desktop}/homebrew.nix
  homebrew.casks = [
    "copilot-cli"
  ];
}
