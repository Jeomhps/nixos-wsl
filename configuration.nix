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
}: {
  nix.settings.experimental-features = [
    "nix-command"
    "flakes"
  ];

  programs.nvf = {
    enable = true;
    settings.vim = {
      enableLuaLoader = true;

      #vim.viAlias = false;
      #vim.vimAlias = true;

      spellcheck = {
        enable = true;
        languages = [
          "en"
          "fr"
        ];
      };

      languages = {
        enableDAP = false;
        enableExtraDiagnostics = true;
        enableFormat = true;
        enableTreesitter = true;

        typst = {
          enable = true;
          # NOTE: bugged in devshells using other archs
          extensions.typst-preview-nvim.enable = true;
          format.type = "typstyle";
          treesitter.enable = true;
        };

        nix = {
          enable = true;
          extraDiagnostics.enable = true;
          treesitter.enable = true;
          format.type = "alejandra";
          lsp = {
            server = "nixd";
            package = pkgs.nixd;
          };
        };
        csharp.enable = true;
        yaml.enable = true;

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
      };

      autocomplete.blink-cmp.enable = true;
      autopairs.nvim-autopairs.enable = true;
      binds.cheatsheet.enable = true;
      comments.comment-nvim.enable = true;

      dashboard.startify = {
        enable = true;
        changeToVCRoot = true; # go to git root on run
      };

      visuals = {
        nvim-scrollbar.enable = false;
        nvim-web-devicons.enable = true;
        nvim-cursorline.enable = true;
        cinnamon-nvim.enable = true;

        highlight-undo.enable = true;
        indent-blankline.enable = true;
      };

      statusline = {
        lualine = {
          enable = true;
          theme = "catppuccin";
        };
      };

      options.termguicolors = true;

      lsp = {
        enable = true;
        formatOnSave = true;
        #otter-nvim.enable = true;
        lspkind.enable = true;
        trouble.enable = true;
      };

      diagnostics.config = {
        underline.enable = true;
        virtual_lines.enable = false;
      };

      telescope.enable = true;
      telescope.setupOpts.pickers.colorscheme.enable_preview = true;

      git = {
        enable = true;
        gitsigns.enable = true;
        gitsigns.codeActions.enable = false;
      };

      autocomplete.nvim-cmp.enable = true;

      theme = {
        enable = true;
        name = "catppuccin";
        style = "mocha";
        #transparent = true;
      };

      filetree = {
        neo-tree = {
          enable = true;
        };
      };

      tabline = {
        nvimBufferline.enable = true;
      };

      terminal = {
        toggleterm = {
          enable = true;
          lazygit.enable = true;
        };
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
    pkgs.neovim
  ];

  wsl.enable = true;

  wsl.defaultUser = "jeomhps";

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

  users.users.jeomhps.extraGroups = ["docker"];

  # This value determines the NixOS release from which the default
  # settings for stateful data, like file locations and database versions
  # on your system were taken. It's perfectly fine and recommended to leave
  # this value at the release version of the first install of this system.
  # Before changing this value read the documentation for this option
  # (e.g. man configuration.nix or on https://nixos.org/nixos/options.html).
  system.stateVersion = "25.05"; # Did you read the comment?
}
