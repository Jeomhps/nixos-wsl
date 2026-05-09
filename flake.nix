{
  description = "Base NixOS-WSL configuration — public, designed to be imported by other flakes";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    NixOS-WSL = {
      url = "github:nix-community/NixOS-WSL/main";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    neovim-config = {
      url = "github:jeomhps/neovim";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs =
    {
      self,
      nixpkgs,
      NixOS-WSL,
      neovim-config,
      ...
    }:
    {
      nixosModules = {
        base = ./modules/base.nix;
        packages = ./modules/packages.nix;

        default = {
          imports = [
            NixOS-WSL.nixosModules.wsl
            neovim-config.nixosModules.default
            self.nixosModules.base
            self.nixosModules.packages
          ];
        };
      };

      nixosConfigurations."nixos-wsl" = nixpkgs.lib.nixosSystem {
        system = "x86_64-linux";
        modules = [
          { nix.registry.nixpkgs.flake = nixpkgs; }
          self.nixosModules.default
        ];
      };
    };
}
