{ ... }:

{
  imports = [
    ../../modules/system-manager
    ./ollama-firewall.nix
  ];

  environment.etc."sddm.conf.d/autologin.conf".text = ''
    [Autologin]
    User=andy
    Session=hyprland
  '';

  # Stationary host: always use the home DNS server, never the router's
  environment.etc."NetworkManager/conf.d/dns.conf".text = ''
    [global-dns-domain-*]
    servers=<home-dns-ip>
  '';
}
