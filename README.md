# nixos-wsl

Base NixOS-WSL configuration — public and designed to be composed by downstream flakes (e.g. a private work flake).

## What's included

| Module | Description |
|---|---|
| `nixosModules.base` | WSL setup, zsh, Docker, nix settings, user |
| `nixosModules.packages` | Full system package set |
| `nixosModules.default` | Everything above + [NixOS-WSL](https://github.com/nix-community/NixOS-WSL) + [neovim](https://github.com/jeomhps/neovim) |

---

## Fresh setup (personal machine)

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
sudo nixos-rebuild boot --flake github:jeomhps/nixos-wsl#nixos
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

### 5. Generate an SSH key and add it to GitHub

```sh
ssh-keygen -t ed25519 -C "170039650+Jeomhps@users.noreply.github.com" -f ~/.ssh/id_ed25519_github
cat ~/.ssh/id_ed25519_github.pub
```

Go to [GitHub Settings - SSH keys](https://github.com/settings/keys) and add the key.

### 6. Fix the chezmoi remote

On first boot chezmoi is initialized over HTTPS. Switch the remote to SSH and set up git identity:

```sh
# Switch remote to SSH
git -C ~/.local/share/chezmoi remote set-url origin git@github.com:jeomhps/dotfiles.git

# Set git identity (if not already in your dotfiles)
git config --global user.name "jeomhps"
git config --global user.email "170039650+Jeomhps@users.noreply.github.com"
```

After that everything should be good.

### 7. Install win32yank on the Windows host (fast clipboard)

Neovim reads the clipboard through a `wsl-paste` helper. Without this step it
falls back to `powershell.exe Get-Clipboard`, which adds ~300–700 ms of
startup overhead on every paste.

From a PowerShell window on the Windows host:

```powershell
# via Scoop
scoop install win32yank

# or via WinGet
winget install equalsraf.win32yank
```

`wsl-paste` detects `win32yank.exe` automatically — no `nixos-rebuild` needed.

---

## Options (`wslBase`)

All options live under the `wslBase` namespace and can be overridden by downstream flakes.

| Option | Type | Default | Description |
|---|---|---|---|
| `wslBase.username` | `str` | `"jeomhps"` | Primary WSL user created at boot |
| `wslBase.neovim.enable` | `bool` | `true` | Enable the [jeomhps/neovim](https://github.com/jeomhps/neovim) config |
| `wslBase.dotfiles.enable` | `bool` | `true` | Auto-run `chezmoi init --apply` on first boot |
| `wslBase.dotfiles.repo` | `str` | `"jeomhps/dotfiles"` | GitHub `user/repo` shorthand or full git URL passed to `chezmoi init` |

---

## Composing from a downstream flake (e.g. work setup)

The `nixosModules.default` export is the main building block. A downstream flake only needs to import it and layer its own config on top.

### Minimal `flake.nix`

```nix
{
  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    nixos-wsl = {
      url = "github:jeomhps/nixos-wsl";
      inputs.nixpkgs.follows = "nixpkgs";
      inputs.neovim-config.follows = "neovim-config"; # see note below
    };
    neovim-config = {
      url = "github:jeomhps/neovim";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs = { nixpkgs, nixos-wsl, ... }: {
    nixosConfigurations."nixos" = nixpkgs.lib.nixosSystem {
      system = "x86_64-linux";
      modules = [
        {
          nix.registry.nixpkgs.flake = nixpkgs;
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

> **`neovim-config` follows** — `nixos-wsl` pins its own `neovim-config` in its `flake.lock`.
> By re-declaring it as a direct input and adding `inputs.neovim-config.follows = "neovim-config"`,
> your downstream flake takes ownership of that pin and you can update neovim independently
> without waiting for `nixos-wsl` to update first:
>
> ```sh
> nix flake update neovim-config   # update only neovim, nothing else
> sudo nixos-rebuild switch --flake .
> ```
>
> Without this, you would need to update `nixos-wsl`'s lock first, then update your flake — a two-step chain.

### Corporate CA / proxy (`your-overrides.nix`)

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

## Updating

```sh
# Update all inputs (run inside the flake directory)
nix flake update

# From a downstream flake, update only the base
nix flake lock --update-input nixos-wsl
```
