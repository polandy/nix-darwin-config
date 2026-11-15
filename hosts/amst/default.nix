{ config, pkgs, lib, self, home-manager, ... }:

# Mac Studio, run headless as the local AI inference server.
{
  imports = [
    ../../modules/macos
    ../../modules/macos/ai-server
    ../../modules/home-manager
    home-manager.darwinModules.home-manager
  ];

  # Hostname matches the flake config name, so `just switch` can derive it via `hostname -s`
  networking.hostName = "amst";
  networking.localHostName = "amst";

  my.aiServer = {
    enable = true;
    # 256 GB machine: 228 GB for the GPU, ~28 GB left for macOS.
    gpuWiredLimitMb = 233472;
    model = "mlx-community/Qwen3-235B-A22B-4bit";
  };

  home-manager.users.andy = import ./home.nix;
}
