{ ... }:

{
  imports = [
    ../../modules/system-manager
    ../../modules/system-manager/llm
  ];

  llm.enable = true;

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
