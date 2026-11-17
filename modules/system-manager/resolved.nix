{ ... }:

{
  # Send single-label names like `nuc` to the DNS server instead of LLMNR only
  environment.etc."systemd/resolved.conf.d/single-label.conf".text = ''
    [Resolve]
    ResolveUnicastSingleLabel=yes
  '';
}
