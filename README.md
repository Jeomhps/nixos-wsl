# nixos-wsl

Base NixOS-WSL configuration — public and designed to be composed by downstream flakes (e.g. a private work flake).

## What's included

| Module | Description |
|---|---|
| `nixosModules.base` | WSL setup, zsh, Docker, nix settings, user |
| `nixosModules.packages` | Full system package set |
| `nixosModules.default` | Everything above + [NixOS-WSL](https://github.com/nix-community/NixOS-WSL) + [neovim](https://github.com/jeomhps/neovim) |

## Direct use (personal machine)

```sh
sudo nixos-rebuild switch --flake github:jeomhps/nixos-wsl#nixos
```

Or after cloning:

```sh
sudo nixos-rebuild switch --flake .#nixos
```

## Composing from a downstream flake (work setup)

The `nixosModules.default` export is the main building block: it bundles NixOS-WSL, the neovim module, and all base configuration. A downstream flake only needs to import it and add its own layer on top.

### Example `flake.nix` (work, private repo)

```nix
{
  description = "Work NixOS-WSL configuration";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    nixos-wsl = {
      url = "github:jeomhps/nixos-wsl";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs = { self, nixpkgs, nixos-wsl, ... }: {
    nixosConfigurations."nixos" = nixpkgs.lib.nixosSystem {
      system = "x86_64-linux";
      modules = [
        { nix.registry.nixpkgs.flake = nixpkgs; wrappers.neovim.enable = true; }
        nixos-wsl.nixosModules.default  # full base stack
        ./work.nix                      # corporate overrides
      ];
    };
  };
}
```

### Example `work.nix` (corporate overrides)

```nix
{ pkgs, ... }:
let
  # Path to the corporate CA certificate (add yours to the repo, gitignored if needed)
  corporateCert = ./certs/corporate-ca.crt;
in
{
  # Inject the corporate CA into nixpkgs cacert so that all nix fetches trust it.
  # This is required when the corporate proxy does SSL inspection.
  # NOTE: causes a one-time full system rebuild (~1h) because cacert is a deep
  # dependency. Worth it — all subsequent builds are fast and correct.
  nixpkgs.overlays = [
    (final: prev: {
      cacert = prev.cacert.overrideAttrs (old: {
        installPhase = (old.installPhase or "") + ''
          cat ${corporateCert} >> $out/etc/ssl/certs/ca-bundle.crt
        '';
      });
    })
  ];

  # Point nix (libcurl) at the patched cacert bundle.
  nix.settings.ssl-cert-file = "${pkgs.cacert}/etc/ssl/certs/ca-bundle.crt";

  # The nix-daemon is a systemd service and does NOT inherit user env vars.
  # Proxy and cert must be set here explicitly.
  systemd.services.nix-daemon.environment = {
    https_proxy       = "http://proxy.corp.internal:9400";
    http_proxy        = "http://proxy.corp.internal:9400";
    NIX_SSL_CERT_FILE = "${pkgs.cacert}/etc/ssl/certs/ca-bundle.crt";
  };

  environment.variables = {
    https_proxy = "http://proxy.corp.internal:9400";
  };

  security.pki.certificateFiles = [ corporateCert ];

  # Override the Docker subnet to avoid conflicts with internal IP ranges.
  virtualisation.docker.daemon.settings.default-address-pools = [
    {
      base = "10.200.0.0/16";
      size = 24;
    }
  ];
}
```

### Applying the work configuration

```sh
sudo nixos-rebuild switch --flake .#nixos
```

## Updating

```sh
# Update all inputs in the base flake
nix flake update

# In your work flake, update only the base flake
nix flake lock --update-input nixos-wsl
```
