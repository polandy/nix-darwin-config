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
| `/home/aiagent/.openrouter-apikey` (aiagent, 0600, one line) | `llm.sandbox.keyFile`; read at runtime, never in the store. Key limit set by hand on openrouter.ai: credit limit 15 USD, reset weekly, expiry 90 days; replace the file when it expires (see [OpenRouter key](#openrouter-key)) |
| `/etc/sudoers.d/aiagent` (root, 0440) | andy may start the sandbox as aiagent and open grants with `oc-net` |
| `/srv/aiagent` (aiagent, 0750, ACL `u:andy:rx`) | clones the agent works in (`llm.sandbox.repos`) |
| `/etc/oc-pr/github-token` (root, 0600, one line) | `llm.sandbox.github.tokenFile`: the GitHub broker's token (`oc-pr`, see [GitHub token](#github-token)); without it `oc-pr` fails, the rest of the sandbox works |
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

### OpenRouter key

Set by hand at <https://openrouter.ai/settings>:

- Keys → the sandbox key: credit limit 15 USD, reset weekly, expiry in 90 days. The budget is
  sized for at most 3 parallel workers; more runs fail on the in-flight reservation (`402`).
- Billing: auto top-up off.
- Privacy: the sandbox sends the data policy with every request (`oc-config`): ZDR endpoints and
  `data_collection: deny` for every repo except `llm.sandbox.publicRepos`, which may use providers
  that collect data. The account setting is the upper bound: with "ZDR endpoints only" on, the
  public repos get ZDR too. Turn it off only if the public repos should use the wider choice.

Replace the key without putting it into shell history or argv:

```bash
sudoedit /home/aiagent/.openrouter-apikey   # one line
sudo chown aiagent:aiagent /home/aiagent/.openrouter-apikey
sudo chmod 600 /home/aiagent/.openrouter-apikey
```

Check after a switch (as andy), then look at <https://openrouter.ai/activity> for the provider,
ZDR and quantization:

```bash
jq '.classes | keys' /etc/llm-policy.json   # contains cloud-fallback
echo 'Reply only: PONG' | sudo -u aiagent /usr/local/bin/oc-sandbox skipper-cd --run
echo 'Reply only: PONG' | sudo -u aiagent /usr/local/bin/oc-sandbox skipper-cd --run \
  --model openrouter/minimax/minimax-m3.1-flash
```

### GitHub token

The broker (`oc-pr`, [llm-module.md](../dev/llm-module.md)) pushes, opens and merges the sandbox
worker's PRs with this token; it never enters the sandbox. Create it at
<https://github.com/settings/personal-access-tokens/new>: fine-grained, resource owner `polandy`,
expiry 90 days, repository access "Only select repositories" with the repos of
`llm.sandbox.repos` (skipper-cd, Stella, framehive, honeycomb), permissions Contents: Read and
write, Pull requests: Read and write (Metadata: Read is added by GitHub). Nothing else, in
particular no Workflows and no Administration. Then, without putting it into history or argv:

```bash
sudo install -d -m 0700 -o root -g root /etc/oc-pr
sudoedit /etc/oc-pr/github-token   # paste the token, one line
sudo chmod 600 /etc/oc-pr/github-token
just switch                         # first time: creates the oc-pr-<repo>.socket units
systemctl list-sockets 'oc-pr-*'    # one socket per repo under /run/oc-proxy
printf '{"verb":"nope"}\n' | sudo -u aiagent socat - UNIX-CONNECT:/run/oc-proxy/pr-skipper-cd.sock
journalctl -u 'oc-pr-skipper-cd@*' -n 3 --no-pager   # "refused: unknown verb"
```

Replace it the same way when it expires; the next connection picks it up.

### Clones

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

#### LFS repos (skipper-cd)

`git-lfs` is a host package (`metapac sync`; the sandbox sees `/usr/bin/git-lfs`). A bundle carries
no LFS objects, so the clone as aiagent holds pointer files only; that is on purpose, the sandbox
has no LFS download path and `oc-sandbox` configures the LFS filter with `--skip` (pointers stay
pointers, objects already in `.git/lfs` are used, nothing is fetched). Nothing to do for clone and
update. To give the agent real file contents, as andy run `git lfs fetch --all` in `~/dev/<repo>`, then
`sudo rsync -a --chown=aiagent: .git/lfs/objects/ /srv/aiagent/<repo>/.git/lfs/objects/`, and in the clone
as aiagent (outside the sandbox, filter not skipping) `git lfs checkout`.
`oc-pr push` refuses a branch that changes LFS-tracked files (the broker cannot upload LFS
objects); andy pushes such branches from his own clone, where `git lfs install` has set up the hooks.
