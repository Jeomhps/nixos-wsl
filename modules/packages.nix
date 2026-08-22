{ lib, pkgs, ... }:
{
  nixpkgs.config.allowUnfreePredicate =
    pkg:
    builtins.elem (lib.getName pkg) [
      "claude-code"
    ];

  environment.systemPackages = with pkgs; [
    # editors
    helix

    # shell / terminal
    atuin
    fastfetch
    starship
    zellij
    zoxide

    # file management
    bat
    dos2unix
    duf
    dust
    eza
    fd
    file
    ncdu
    ouch
    tree

    # git
    git
    lazygit

    # dotfiles
    chezmoi

    # languages / runtimes
    bun
    #cargo
    #cargo-binstall
    gcc
    go
    lua
    python3
    #rustc
    uv

    # devops / containers / k8s
    act
    lazydocker
    yq-go

    # security
    gnupg
    gopass
    picocrypt-cli
    picocrypt-ng
    pinentry-tty

    # CLI utilities
    btop
    fzf
    gdu
    hyperfine
    jq
    openssl
    ripgrep
    xh
    tv
    yubikey-manager

    # network
    bind
    tcpdump

    # documentation
    tealdeer
    claude-code
  ];
}
