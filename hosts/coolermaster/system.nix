{ ... }:

{
  imports = [
    ../../modules/system-manager
    ../../modules/system-manager/llm
  ];

  llm = {
    enable = true;
    # Created by hand, owned by the agent user, mode 0400; never read by Nix.
    sandbox.keyFile = "/home/aiagent/.openrouter-apikey";
  };

  environment.etc."sddm.conf.d/autologin.conf".text = ''
    [Autologin]
    User=andy
    Session=hyprland
  '';

  # Stationary host: always use the home DNS server, never the router's.
  # The LAN address stays out of this public repo, so the file is host-local:
  # /etc/NetworkManager/conf.d/dns-local.conf containing
  #   [global-dns-domain-*]
  #   servers=<home-dns-ip>
}
