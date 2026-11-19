# coolermaster: host-local files

This repo is public, so LAN addresses are not part of it. coolermaster reads them from files that
live only on the host and are not managed by Nix. Create them by hand on a fresh install, before the
first `just switch`.

| File | Read by | Without it |
|---|---|---|
| `/etc/NetworkManager/conf.d/dns-local.conf` | NetworkManager | DNS comes from the router instead of the home DNS server |
| `/etc/ollama-lan/allowed.nft` | `ollama-lan-firewall.service` ([firewall.nix](../../modules/system-manager/llm/firewall.nix)) | Ollama (port 11434) is reachable only from localhost and the sandbox Caddy (no LAN host needs it today) |

## Setup

Replace `<home-dns-ip>` and `<nuc-ip>` with the real addresses.

```bash
# Home DNS server for NetworkManager
printf '[global-dns-domain-*]\nservers=<home-dns-ip>\n' \
  | sudo tee /etc/NetworkManager/conf.d/dns-local.conf
sudo nmcli general reload conf

# Only if a LAN host needs Ollama (comma-separated, CIDR ranges work too). Since 2026-11-19
# none does: the nuc monitors through the exporters, not the Ollama port.
sudo mkdir -p /etc/ollama-lan
echo 'add element inet ollama_lan allowed { <lan-ip> }' \
  | sudo tee /etc/ollama-lan/allowed.nft
sudo systemctl restart ollama-lan-firewall   # skip before the first switch, the unit does not exist yet
```

NetworkManager does not pick up config changes by itself, so reload it after editing the DNS file.
The firewall rules include every `/etc/ollama-lan/*.nft`, so more files can sit next to
`allowed.nft`.

## Check

```bash
grep -v '^#' /etc/resolv.conf                       # only the home DNS server
sudo nft list set inet ollama_lan allowed           # empty unless a LAN host was added
ssh nuc curl -s -m 5 http://coolermaster:11434/api/version   # times out: LAN is blocked
```
