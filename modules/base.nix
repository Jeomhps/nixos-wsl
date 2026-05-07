{ pkgs, ... }:
{
  nix.settings = {
    experimental-features = [ "nix-command" "flakes" ];
  };

  wsl = {
    enable = true;
    defaultUser = "jeomhps";
    interop = {
      register = true; # registers binfmt_misc for .exe files
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
    users.jeomhps.extraGroups = [ "docker" ];
  };

  # This value determines the NixOS release from which the default settings for
  # stateful data, like file locations and database versions on your system were
  # taken. Before changing this value read the documentation for this option.
  system.stateVersion = "25.05";
}
