{ config, pkgs, lib, self, ... }:

{
  homebrew = {
    enable = true;
    onActivation.cleanup = "zap";
    brews = [
      "gemini-cli"
    ];
    casks = [
      "claude-code"
    ];
  };
}
