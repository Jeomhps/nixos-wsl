# nixos-wsl

Base NixOS-WSL configuration — public and designed to be composed by downstream flakes (e.g. a private work flake).

## What's included

| Module | Description |
|---|---|
| `nixosModules.base` | WSL setup, zsh, Docker, nix settings, user |
| `nixosModules.packages` | Full system package set |
| `nixosModules.default` | Everything above + [NixOS-WSL](https://github.com/nix-community/NixOS-WSL) + [neovim](https://github.com/jeomhps/neovim) |

---

## Options (`wslBase`)

All options live under the `wslBase` namespace and can be overridden by downstream flakes.

| Option | Type | Default | Description |
|---|---|---|---|
| `wslBase.hostname` | `str` | `"nixos-wsl"` | System hostname |
| `wslBase.username` | `str` | `"jeomhps"` | Primary WSL user created at boot |
| `wslBase.neovim.enable` | `bool` | `true` | Enable the [jeomhps/neovim](https://github.com/jeomhps/neovim) config |
| `wslBase.dotfiles.enable` | `bool` | `true` | Auto-run `chezmoi init --apply` on first boot |
| `wslBase.dotfiles.repo` | `str` | `"jeomhps/dotfiles"` | GitHub `user/repo` shorthand or full git URL passed to `chezmoi init` |

---

## Fresh setup — personal machine

### 1. Import the NixOS-WSL tarball

Download the latest release tarball from [nix-community/NixOS-WSL releases](https://github.com/nix-community/NixOS-WSL/releases), then import it into WSL from PowerShell:

```powershell
wsl --import NixOS E:\WSL\NixOS D:\Downloads\nixos.wsl
```

### 2. Boot into the new distro

```powershell
wsl -d NixOS
```

### 3. Apply the configuration

> Use `boot` and not `switch` — the config changes the default username from `nixos` to `jeomhps`, and using `switch` can leave the new user misconfigured.

```sh
sudo nixos-rebuild boot --flake github:jeomhps/nixos-wsl#nixos-wsl --no-write-lock-file
```

### 4. Apply the new username

Exit the WSL shell, then from PowerShell run these commands in order:

```powershell
# Stop the distro
wsl -t NixOS

# Boot into the new generation as root to apply the user change
wsl -d NixOS --user root exit

# Stop it again
wsl -t NixOS

# Reopen — you are now logged in as jeomhps
wsl -d NixOS
```

> chezmoi dotfiles will initialize automatically on this first boot as the new user.

### 5. Enable systemd user session (linger)

Run this once to prevent the `Failed to start the systemd user session` warning on every WSL startup:

```sh
sudo loginctl enable-linger jeomhps
```

> This writes a marker file to `/var/lib/systemd/linger/` and persists across reboots. It cannot be set via `nixos-rebuild` in WSL due to a missing D-Bus connection during activation.

### 6. Generate an SSH key and add it to GitHub

```sh
ssh-keygen -t ed25519 -C "170039650+Jeomhps@users.noreply.github.com" -f ~/.ssh/id_ed25519_github
cat ~/.ssh/id_ed25519_github.pub
```

Go to [GitHub Settings - SSH keys](https://github.com/settings/keys) and add the key.

### 7. Fix the chezmoi remote

On first boot chezmoi is initialized over HTTPS. Run the helper function to switch all dotfile remotes to SSH:

```sh
fix-dotfiles-upstream
```

### 8. Install win32yank on the Windows host (fast clipboard)

Neovim reads the clipboard through a `wsl-paste` helper. Without this step it falls back to `powershell.exe Get-Clipboard`, which adds ~300–700 ms of startup overhead on every paste.

From a PowerShell window on the Windows host:

```powershell
# via Scoop
scoop install win32yank

# or via WinGet
winget install equalsraf.win32yank
```

`wsl-paste` detects `win32yank.exe` automatically — no `nixos-rebuild` needed.

---

## Fresh setup — work machine

### 1. Create the downstream flake

In your private work repo, create a `flake.nix` that imports this base module and overrides the relevant options:

```nix
{
  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    NixOS-WSL = {
      url = "github:nix-community/NixOS-WSL/main";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    nixos-wsl = {
      url = "github:jeomhps/nixos-wsl";
      inputs.nixpkgs.follows = "nixpkgs";
      inputs.NixOS-WSL.follows = "NixOS-WSL";
      inputs.neovim-config.follows = "neovim-config";
    };
    neovim-config = {
      url = "github:jeomhps/neovim";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs = { nixpkgs, nixos-wsl, ... }: {
    nixosConfigurations."work-machine" = nixpkgs.lib.nixosSystem {
      system = "x86_64-linux";
      modules = [
        {
          nix.registry.nixpkgs.flake = nixpkgs;
          wslBase.hostname      = "work-machine";
          wslBase.username      = "youruser";
          wslBase.dotfiles.repo = "youruser/dotfiles";
          # wslBase.neovim.enable = false;  # opt out of the neovim config
        }
        nixos-wsl.nixosModules.default
        ./your-overrides.nix
      ];
    };
  };
}
```

> **`follows` pins** — `nixos-wsl` carries its own `flake.lock` entries for both `NixOS-WSL` and `neovim-config`.
> By re-declaring them as direct inputs and adding the matching `follows` lines, your downstream
> flake takes ownership of those pins and can update each one independently:
>
> ```sh
> nix flake update NixOS-WSL      # pull latest NixOS-WSL
> nix flake update neovim-config  # pull latest neovim config
> sudo nixos-rebuild switch --flake .
> ```

See [Corporate CA / proxy](#corporate-ca--proxy) if you are behind an SSL-inspecting proxy.

### 2. Create the chezmoi local config

Before chezmoi runs on first boot, the local config must already exist on the machine. Create it **before** applying the flake:

```sh
mkdir -p ~/.config/chezmoi
cat > ~/.config/chezmoi/chezmoi.toml <<'EOF'
[data]
  work_git_username = "yourworkname"
  work_git_email    = "you@company.com"
  work_vcs_host     = "git.company.com"
  work_ado_org      = "mycompany"      # optional — only add if you use Azure DevOps
EOF
```

This file is never committed. When present, chezmoi deploys `~/.config/git/config-work` and wires up `[includeIf]` blocks in `~/.config/git/config` so the work identity is used automatically for any repo whose remote matches `work_vcs_host` (and Azure DevOps if `work_ado_org` is set).

### 3. Import the NixOS-WSL tarball

```powershell
wsl --import NixOS E:\WSL\NixOS D:\Downloads\nixos.wsl
```

### 4. Boot into the new distro

```powershell
wsl -d NixOS
```

### 5. Apply the work flake

> Use `boot` and not `switch` — same reason as the personal setup.

```sh
sudo nixos-rebuild boot --flake github:your-org/your-work-flake#work-machine --no-write-lock-file
```

### 6. Apply the new username

Exit the WSL shell, then from PowerShell:

```powershell
wsl -t NixOS
wsl -d NixOS --user root exit
wsl -t NixOS
wsl -d NixOS
```

> chezmoi dotfiles will initialize automatically on this first boot. The chezmoi local config created in step 2 will be picked up and the work git identity deployed.

### 7. Enable systemd user session (linger)

```sh
sudo loginctl enable-linger youruser
```

> This may or may not be needed depending on the environment — skip and revisit if you see `Failed to start the systemd user session` warnings on WSL startup.

### 8. Generate SSH keys

Generate keys for GitHub and your work VCS host:

```sh
ssh-keygen -t ed25519 -C "170039650+Jeomhps@users.noreply.github.com" -f ~/.ssh/id_ed25519_github
ssh-keygen -t ed25519 -C "you@company.com" -f ~/.ssh/id_ed25519_work
```

Add each public key to the respective platform:

```sh
cat ~/.ssh/id_ed25519_github.pub   # → GitHub Settings / SSH keys
cat ~/.ssh/id_ed25519_work.pub     # → your work VCS SSH keys
```

> Don't forget to create `~/.ssh/config` to map each host to the right key — otherwise SSH will not know which identity to use for which remote.

### 9. Fix the chezmoi remote

Run the helper function to switch all dotfile remotes to SSH:

```sh
fix-dotfiles-upstream
```

### 10. Install win32yank on the Windows host (fast clipboard)

```powershell
# via Scoop
scoop install win32yank

# or via WinGet
winget install equalsraf.win32yank
```

---

## Corporate CA / proxy

When behind a proxy that does SSL inspection, use a lean `runCommand` bundle instead of overriding `cacert` (avoids a full mass rebuild):

```nix
{ pkgs, ... }:
let
  caBundle = pkgs.runCommand "corporate-ca-bundle" {} ''
    cat ${pkgs.cacert}/etc/ssl/certs/ca-bundle.crt \
        ${./certs/corporate-ca.crt} > $out
  '';
in
{
  nix.settings.ssl-cert-file = "${caBundle}";

  systemd.services.nix-daemon.environment = {
    https_proxy       = "http://proxy.corp.internal:9400";
    http_proxy        = "http://proxy.corp.internal:9400";
    NIX_SSL_CERT_FILE = "${caBundle}";
  };

  environment.variables.https_proxy = "http://proxy.corp.internal:9400";

  security.pki.certificateFiles = [ ./certs/corporate-ca.crt ];
}
```

Place your corporate CA certificate (PEM format) at `certs/corporate-ca.crt` next to your flake.

---

## Known issues

### Hostname rename — aliases break on first rebuild

The shell aliases (`upgrade`, `update`, etc.) use `.#` as the flake attribute, which Nix resolves to the **current system hostname**. If you rename `wslBase.hostname` in your flake (or set it for the first time on an existing machine that still has the old hostname), the rebuild will fail because the old hostname no longer matches any `nixosConfigurations` entry:

```
error: flake does not provide attribute 'nixosConfigurations."old-name"'
```

Fix: run the rebuild **once** with the new name spelled out explicitly:

```sh
sudo nixos-rebuild switch --flake .#new-hostname
```

After that the system hostname matches the flake attribute and `.#` resolves correctly again.

### Hostname change requires a WSL distro restart to take effect

`networking.hostName` is forwarded to `/etc/wsl.conf` under `[network] hostname`. WSL only reads `wsl.conf` at distro startup — a `nixos-rebuild switch` alone is not enough.

After rebuilding, restart the distro from PowerShell on the Windows host:

```powershell
wsl -t NixOS   # terminate the running distro
wsl -d NixOS   # start it again — wsl.conf is re-read here
```

You can confirm the change took effect with `hostname` inside WSL.

---

## Updating

```sh
# Update all inputs (run inside the flake directory)
nix flake update

# From a downstream flake, update only the base
nix flake lock --update-input nixos-wsl
```
