{ lib, pkgs, config, ... }:
{
  options.wslBase = {
    hostname = lib.mkOption {
      type = lib.types.str;
      default = "nixos-wsl";
      description = "System hostname. Override in downstream flakes (e.g. work machine).";
    };

    username = lib.mkOption {
      type = lib.types.str;
      default = "jeomhps";
      description = "Primary WSL user. Downstream flakes can override this.";
    };

    neovim = {
      enable = lib.mkEnableOption "neovim config from jeomhps/neovim" // { default = true; };
    };

    dotfiles = {
      enable = lib.mkEnableOption "auto-apply chezmoi dotfiles on first boot" // { default = true; };
      repo = lib.mkOption {
        type = lib.types.str;
        default = "jeomhps/dotfiles";
        description = "Passed to 'chezmoi init'. Accepts a GitHub 'user/repo' shorthand or any full git URL.";
      };
    };
  };

  config = lib.mkMerge [
    {
      wrappers.neovim.enable = config.wslBase.neovim.enable;

      networking.hostName = config.wslBase.hostname;

      nix.settings = {
        experimental-features = [ "nix-command" "flakes" ];
      };

      wsl = {
        enable = true;
        defaultUser = config.wslBase.username;
        interop = {
          register = true;
          includePath = true;
        };
      };

      networking.firewall.enable = false;

      # Allow unpatched dynamic binaries (e.g. Zed, VS Code) to run on NixOS.
      programs.nix-ld.enable = true;

      programs.zsh = {
        enable = true;
        enableCompletion = true;
        autosuggestions.enable = true;
        syntaxHighlighting.enable = true;

        histSize = 1000;
        histFile = "$HOME/.zsh_history";
        setOptions = [ "HIST_IGNORE_ALL_DUPS" ];
      };

      virtualisation.docker = {
        enable = true;
        daemon.settings = {
          experimental = true;
          # 10.123.0.0/16 is intentionally non-standard: avoids Docker's own auto-pool
          # (172.16-31.x), AWS/Azure (10.0-50.x), GCP (10.128-255.x), K8s CNIs
          # (10.244.x, 10.96.x), and common corporate/home LANs (192.168.x).
          default-address-pools = [
            {
              base = "10.123.0.0/16";
              size = 24;
            }
          ];
        };
      };

      users = {
        defaultUserShell = pkgs.zsh;
        users.${config.wslBase.username}.extraGroups = [ "docker" "plugdev" ];
      };

      services.pcscd.enable = true;

      users.groups.plugdev = {};

      environment.etc."udev/rules.d/99-yubikey.rules".text = ''
        SUBSYSTEM=="usb", ATTR{idVendor}=="1050", GROUP="plugdev", MODE="0660"
      '';

      system.stateVersion = "25.05";
    }

    (lib.mkIf config.wslBase.dotfiles.enable {
      systemd.services.chezmoi-init = {
        description = "Initialize chezmoi dotfiles on first boot";
        wantedBy = [ "multi-user.target" ];
        after = [ "network-online.target" ];
        wants = [ "network-online.target" ];
        serviceConfig = {
          Type = "oneshot";
          User = config.wslBase.username;
          RemainAfterExit = true;
          ExecStart = pkgs.writeShellScript "chezmoi-init" ''
            set -eu
            if [ ! -d "$HOME/.local/share/chezmoi/.git" ]; then
              echo "chezmoi: first boot, initializing from ${config.wslBase.dotfiles.repo}..."
              exec ${pkgs.chezmoi}/bin/chezmoi init --apply "${config.wslBase.dotfiles.repo}"
            else
              echo "chezmoi: already initialized, skipping."
            fi
          '';
        };
      };
    })
  ];
}
