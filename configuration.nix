{
  pkgs,
  inputs,
  ...
}: {
  nix.settings.experimental-features = [
    "nix-command"
    "flakes"
  ];

  wsl = {
    enable = true;
    defaultUser = "jeomhps";
  };

  environment.systemPackages = [
    # My nvim flake import
    inputs.my-nvim.packages.${pkgs.system}.default

    pkgs.zellij
    pkgs.bat
    pkgs.chezmoi
    pkgs.starship
    pkgs.git
    pkgs.eza
    pkgs.duf
    pkgs.lazygit
    pkgs.lazydocker
    pkgs.typst
    pkgs.dive
    pkgs.bind
    pkgs.neofetch
    pkgs.go
    pkgs.gcc
    pkgs.gopass
    pkgs.nnn
    pkgs.fzf
    pkgs.just
    pkgs.proxychains-ng
    pkgs.btop
    pkgs.glances
    pkgs.wslu
    pkgs.ripgrep
    pkgs.delta
    pkgs.navi
    pkgs.tokei
    pkgs.hyperfine
    pkgs.httpie
    pkgs.nmap
    pkgs.ansible
    pkgs.netcat
  ];

  # Shell
  programs.zsh = {
    enable = true;
    enableCompletion = true;
    autosuggestions.enable = true;
    syntaxHighlighting.enable = true;
    histSize = 1000;
    histFile = "$HOME/.zsh_history";
    setOptions = [
      "HIST_IGNORE_ALL_DUPS"
    ];
  };

  users.defaultUserShell = pkgs.zsh;

  # Docker
  virtualisation.docker = {
    enable = true;
    daemon.settings = {
      experimental = true;
      default-address-pools = [
        {
          base = "10.200.0.0/16";
          size = 24;
        }
      ];
    };
  };

  users.users.jeomhps.extraGroups = ["docker"];

  time.timeZone = "Europe/Paris";

  # This value determines the NixOS release from which the default
  # settings for stateful data, like file locations and database versions
  # on your system were taken. It's perfectly fine and recommended to leave
  # this value at the release version of the first install of this system.
  # Before changing this value read the documentation for this option
  # (e.g. man configuration.nix or on https://nixos.org/nixos/options.html).
  system.stateVersion = "25.05"; # Did you read the comment?
}
