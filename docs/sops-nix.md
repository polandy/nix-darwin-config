# sops-nix Setup

This document describes how secrets management with [sops-nix](https://github.com/Mic92/sops-nix) was set up in this repo, and how to maintain it.

## How it works

- [sops](https://github.com/getsops/sops) encrypts secret values inside YAML files using [age](https://github.com/FiloSottile/age) keys
- sops-nix is a NixOS/Home Manager module that decrypts those files at activation time
- Encrypted files (`secrets/*.yaml`) are safe to commit — they contain only AES256-GCM ciphertext
- The age private key lives at `~/.config/sops/age/keys.txt` on each machine that needs to decrypt. It is never committed.

At `darwin-rebuild switch`, sops-nix reads the age key, decrypts each secret to a file (e.g. `/run/user/<uid>/secrets/syncthing/homelab_id`), and sets ownership/permissions. Home Manager modules reference the decrypted path via `config.sops.secrets.<name>.path`.

---

## Initial setup steps performed on amba

### 1. Install prerequisites

Tools were made available via `nix shell`:

```sh
nix shell nixpkgs#sops nixpkgs#age nixpkgs#ssh-to-age
```

These are not yet added as permanent packages — add them to `modules/base/packages.nix` when desired.

### 2. Generate the age private key

The age private key is derived from the SSH ed25519 private key using [ssh-to-age](https://github.com/mic92/ssh-to-age). The SSH key at `~/.ssh/id_ed25519` has no passphrase (required for `ssh-to-age` to work).

```sh
mkdir -p ~/.config/sops/age
ssh-to-age -private-key -i ~/.ssh/id_ed25519 -o ~/.config/sops/age/keys.txt

# Derive the age public key (use this in .sops.yaml):
cat ~/.ssh/id_ed25519.pub | ssh-to-age
# Output: age17hew4gnwapvvv53vyzmcgsk8y65spqg79r0kzs2dfpacteewts7s5dqdwz
```

> **Note:** The age private key is fully recoverable from `~/.ssh/id_ed25519`. Back up the SSH private key (e.g. in Bitwarden and KeePassXC). If the SSH key is lost, re-run `ssh-to-age` on the restored key to regenerate `~/.config/sops/age/keys.txt`.
>
> **Note:** `ssh-to-age` does not support passphrase-protected SSH keys. The SSH key at `~/.ssh/id_ed25519` must have no passphrase.

### 3. Create `.sops.yaml`

Added to repo root. Declares the age public key for amba and a creation rule so any `secrets/*.yaml` file is encrypted for that key:

```yaml
keys:
  - &amba age1a38p5ur3qfj4flfvjddqdzvhnm8eed390e8v220lxntd3g6jug0qcqytqj

creation_rules:
  - path_regex: secrets/.*\.yaml$
    key_groups:
      - age:
          - *amba
```

### 4. Create the encrypted secrets file

```sh
# Write plaintext to a file inside secrets/ so it matches the path_regex
cat > secrets/syncthing_plain.yaml << 'EOF'
syncthing:
    homelab_id: <id>
    ipm_id: <id>
    pixel9_id: <id>
EOF

SOPS_AGE_KEY_FILE=~/.config/sops/age/keys.txt \
  sops --encrypt secrets/syncthing_plain.yaml > secrets/syncthing.yaml

rm secrets/syncthing_plain.yaml
git add secrets/syncthing.yaml  # encrypted, safe to commit
```

Verify decryption works:

```sh
SOPS_AGE_KEY_FILE=~/.config/sops/age/keys.txt sops --decrypt secrets/syncthing.yaml
```

### 5. Add sops-nix to `flake.nix`

```nix
inputs = {
  sops-nix.url = "github:Mic92/sops-nix";
  sops-nix.inputs.nixpkgs.follows = "nixpkgs";
};

outputs = inputs@{ ..., sops-nix, ... }:
# In amba's darwinSystem:
specialArgs = { inherit self lib home-manager sops-nix; };
```

### 6. Add sops-nix Home Manager module to amba

In `hosts/amba/default.nix`:

```nix
home-manager.sharedModules = [ sops-nix.homeManagerModules.sops ];
```


---


## Adding another host

When a new host needs to decrypt secrets (e.g. during its own `darwin-rebuild switch` or `nixos-rebuild`), you need to:

1. Get the host's age public key
2. Add it to `.sops.yaml`
3. Re-encrypt secrets so the new key can decrypt them
4. Wire up sops-nix in the host's Nix config
5. Put the age private key on the host

### Step 1 — Get the age public key for the new host

**Option A — Mac with a no-passphrase SSH key (recommended, same as amba):**

```sh
# On the new Mac:
ssh-keygen -t ed25519 -f ~/.ssh/id_ed25519 -N ""   # skip if key already exists without passphrase
cat ~/.ssh/id_ed25519.pub | ssh-to-age
# → age1xyz...
```

**Option B — NixOS or Linux server (use the host SSH key):**

```sh
# From any machine that can reach the host:
ssh-keyscan <hostname> | grep ed25519 | ssh-to-age
# → age1xyz...
```

### Step 2 — Add the key to `.sops.yaml`

In `.sops.yaml` at the repo root, add the new public key and include it in the creation rule:

```yaml
keys:
  - &amba age17hew4gnwapvvv53vyzmcgsk8y65spqg79r0kzs2dfpacteewts7s5dqdwz  # amba
  - &ambp age1xyz...                                                          # new host

creation_rules:
  - path_regex: secrets/.*\.yaml$
    key_groups:
      - age:
          - *amba
          - *ambp
```

### Step 3 — Re-encrypt secrets for the new key

Run this from the repo root on amba (which already has the age private key):

```sh
SOPS_AGE_KEY_FILE=~/.config/sops/age/keys.txt sops updatekeys secrets/syncthing.yaml
```

Sops will show the keys being added/removed and update the file. Commit the result:

```sh
git add .sops.yaml secrets/syncthing.yaml
git commit -m "secrets: add <hostname> as sops recipient"
```

### Step 4 — Wire up sops-nix in the host's Nix config

In `flake.nix`, pass `sops-nix` in `specialArgs` for the new host:

```nix
"ambp" = nix-darwin.lib.darwinSystem {
  inherit system;
  specialArgs = { inherit self lib home-manager sops-nix; };
  modules = [ ./hosts/ambp ... ];
};
```

In `hosts/ambp/default.nix`, add the Home Manager module:

```nix
home-manager.sharedModules = [ sops-nix.homeManagerModules.sops ];
```

In the relevant Home Manager module (e.g. `modules/home-manager/syncthing.nix`), set the age key path:

```nix
sops.age.keyFile = "/Users/<username>/.config/sops/age/keys.txt";
```

### Step 5 — Put the age private key on the new host

**For Option A (Mac with SSH key):**

On the new Mac, derive the age private key from the SSH key:

```sh
mkdir -p ~/.config/sops/age
ssh-to-age -private-key -i ~/.ssh/id_ed25519 -o ~/.config/sops/age/keys.txt
chmod 600 ~/.config/sops/age/keys.txt
```

**For Option B (NixOS server):**

The host SSH private key is already on the machine. Tell sops-nix to use it directly by setting in the NixOS module:

```nix
sops.age.sshKeyPaths = [ "/etc/ssh/ssh_host_ed25519_key" ];
```

(No manual key derivation needed — sops-nix handles it automatically.)

### Verification

```sh
# On the new host, after darwin-rebuild switch / nixos-rebuild switch:
SOPS_AGE_KEY_FILE=~/.config/sops/age/keys.txt sops --decrypt secrets/syncthing.yaml
```

---

## Editing an existing secret

```sh
SOPS_AGE_KEY_FILE=~/.config/sops/age/keys.txt sops secrets/syncthing.yaml
# Opens $EDITOR with decrypted content; saves re-encrypted on exit
```

---

## Verification

```sh
# 1. Build succeeds
darwin-rebuild build --flake .#amba

# 2. Apply
darwin-rebuild switch --flake .#amba

# 3. Check decrypted secret files exist
ls /run/user/$(id -u)/secrets/

# 4. Confirm encrypted file has no plaintext (replace <secret-substring> with a part of a known secret)
grep -c "<secret-substring>" secrets/syncthing.yaml  # should return 0
```
