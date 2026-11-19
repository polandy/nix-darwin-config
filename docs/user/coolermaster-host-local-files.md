# coolermaster: host-local files

Some of coolermaster's state lives only on the host and is not managed by Nix: LAN addresses (this
repo is public), the opencode sandbox's agent user, its key and its sudoers rules. Create them by
hand on a fresh install, before the first `just switch`.

| File | Read by | Without it |
|---|---|---|
| `/etc/NetworkManager/conf.d/dns-local.conf` | NetworkManager | DNS comes from the router instead of the home DNS server |
| `/etc/ollama-lan/allowed.nft` | `ollama-lan-firewall.service` ([firewall.nix](../../modules/system-manager/llm/firewall.nix)) | Ollama (port 11434) is reachable only from localhost and the addresses in `/etc/ollama-lan/*.nft`; without a file, localhost only (no other host needs it today) |

## Network

Replace `<home-dns-ip>` and `<nuc-ip>` with the real addresses.

```bash
# Home DNS server for NetworkManager
printf '[global-dns-domain-*]\nservers=<home-dns-ip>\n' \
  | sudo tee /etc/NetworkManager/conf.d/dns-local.conf
sudo nmcli general reload conf

# Only if another host needs Ollama (comma-separated, CIDR ranges work too). Since 2026-11-19
# none does: the nuc monitors through the exporters, not the Ollama port.
sudo mkdir -p /etc/ollama-lan
echo 'add element inet ollama_lan allowed { <ip> }' \
  | sudo tee /etc/ollama-lan/allowed.nft
sudo systemctl restart ollama-lan-firewall   # skip before the first switch, the unit does not exist yet
journalctl -u ollama-lan-firewall -n 3 --no-pager   # lists the loaded allow files, or "localhost only"
```

The same applies to the Caddy of the Docker sandbox (path B), if it is used again: put the fixed
address of its container into its own file, e.g. `/etc/ollama-lan/docker-caddy.nft`. Add only
that single address, not a Docker range such as 172.16.0.0/12, or agent containers reach Ollama
past Caddy's filter through their bridge gateway.

NetworkManager does not pick up config changes by itself, so reload it after editing the DNS file.
The firewall rules include every `/etc/ollama-lan/*.nft`, so more files can sit next to
`allowed.nft`.

Check:

```bash
grep -v '^#' /etc/resolv.conf                       # only the home DNS server
sudo nft list set inet ollama_lan allowed           # empty unless a LAN host was added
ssh nuc curl -s -m 5 http://coolermaster:11434/api/version   # times out: LAN is blocked
```

## opencode sandbox

The tooling comes from [`modules/system-manager/llm`](../../modules/system-manager/llm/) (usage:
header of `sandbox/oc-sandbox`). The host needs:

| What | Why |
|---|---|
| user `aiagent` (own group, no login, locked, home 0700) | the sandbox runs as this user; nft rules match its uid |
| `/home/aiagent/.openrouter-apikey` (aiagent, 0600, one line) | `llm.sandbox.keyFile`; read at runtime, never in the store. Create the key with a credit limit and an expiry, and replace the file when it expires |
| `/etc/sudoers.d/aiagent` (root, 0440) | andy may start the sandbox as aiagent and open grants with `oc-net` |
| `/srv/aiagent` (aiagent, 0750, ACL `u:andy:rx`) | clones the agent works in (`llm.sandbox.repos`) |
| `sysctl dev.tty.legacy_tiocsti` = `0` | `oc-sandbox` refuses to start otherwise (Arch kernel default) |

Do not enable `nftables.service`: `/etc/nftables.conf` drops input and breaks Docker; the sandbox
rules come from `oc-nft.service`.

```bash
sudo useradd -m -s /usr/bin/nologin -U aiagent
sudo passwd -l aiagent
sudo chmod 700 /home/aiagent
# place the key yourself, e.g. with an editor as root, then:
sudo chown aiagent:aiagent /home/aiagent/.openrouter-apikey
sudo chmod 600 /home/aiagent/.openrouter-apikey

printf '%s\n' 'andy ALL=(aiagent) NOPASSWD: /usr/local/bin/oc-sandbox' \
  'andy ALL=(root) NOPASSWD: /usr/local/bin/oc-net' > aiagent.sudoers
sudo visudo -cf aiagent.sudoers
sudo install -m 0440 -o root -g root aiagent.sudoers /etc/sudoers.d/aiagent

sudo install -d -m 0750 -o aiagent -g aiagent /srv/aiagent
sudo setfacl -m u:andy:rx /srv/aiagent
```

Clone a repo into `/srv/aiagent` (andy's home is 0700, so via a bundle on stdin; the clone has no
remote, andy fetches from it):

```bash
cd ~/dev/<repo>
git bundle create - main | sudo -u aiagent sh -c 'umask 077; cat > /srv/aiagent/<repo>.bundle'
sudo -u aiagent sh -c 'cd /srv/aiagent \
  && git clone -q -b main <repo>.bundle <repo> && rm <repo>.bundle && cd <repo> \
  && git remote remove origin && git config user.name "opencode (aiagent)" \
  && git config user.email aiagent@localhost && git config commit.gpgsign false'
sudo setfacl -R -m u:andy:rX /srv/aiagent/<repo>
sudo find /srv/aiagent/<repo> -type d -exec setfacl -d -m u:andy:rX,u:aiagent:rwX {} +
git remote add aiagent /srv/aiagent/<repo> && git remote set-url --push aiagent DISABLED
```

To update the clone later, create the bundle the same way and run
`git fetch ../<repo>.bundle main:refs/remotes/andy/main` in it as aiagent.
