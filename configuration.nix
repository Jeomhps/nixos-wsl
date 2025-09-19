# Edit this configuration file to define what should be installed on
# your system. Help is available in the configuration.nix(5) man page, on
# https://search.nixos.org/options and in the NixOS manual (`nixos-help`).
# NixOS-WSL specific options are documented on the NixOS-WSL repository:
# https://github.com/nix-community/NixOS-WSL
{
  config,
  lib,
  pkgs,
  ...
}:
{
  nix.settings.experimental-features = [
    "nix-command"
    "flakes"
  ];
  #  security.pki.certificateFiles = [
  #    secrets.certPath
  #  ];

  programs.nvf = {
    enable = true;
    settings = {
      #vim.viAlias = false;
      #vim.vimAlias = true;
      vim.languages = {
        nix.enable = true;
        markdown.enable = true;
        bash.enable = true;
        clang.enable = true;
        css.enable = true;
        html.enable = true;
        sql.enable = true;
        #java.enable = true;
        #kotlin.enable = true;
        ts.enable = true;
        go.enable = true;
        lua.enable = true;
        #zig.enable = true;
        python.enable = true;
        typst.enable = true;
      };
      vim.lsp = {
        enable = true;
        formatOnSave = true;
      };
      vim.theme = {
        enable = true;
        name = "catppuccin";
        style = "mocha";
        transparent = true;
      };
    };
  };
  environment.systemPackages = [
    pkgs.helix
    pkgs.vim
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
  ];
  wsl.enable = true;
  wsl.defaultUser = config.secrets.username;
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
  virtualisation.docker = {
    enable = true;
    # Set up resource limits
    daemon.settings = {
      experimental = true;
      #bip = "10.200.1.0/24";
      default-address-pools = [
        {
          base = "10.200.0.0/16";
          size = 24;
        }
      ];
    };
  };

  users.users.${config.secrets.username}.extraGroups = [ "docker" ];

  # This value determines the NixOS release from which the default
  # settings for stateful data, like file locations and database versions
  # on your system were taken. It's perfectly fine and recommended to leave
  # this value at the release version of the first install of this system.
  # Before changing this value read the documentation for this option
  # (e.g. man configuration.nix or on https://nixos.org/nixos/options.html).
  system.stateVersion = "25.05"; # Did you read the comment?
}
