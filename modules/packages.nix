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
    kubectl
    fluxcd
    flux9s
    k9s

    # security
    gnupg
    gopass
    picocrypt-cli
    picocrypt-ng
    pinentry-tty
    x11_ssh_askpass

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
    opentofu

    # network
    bind
    tcpdump

    # documentation
    tealdeer
    claude-code
  ];
}
