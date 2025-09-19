{
  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    NixOS-WSL = {
      url = "github:nix-community/NixOS-WSL/main";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    nvf = {
      url = "github:NotAShelf/nvf";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };
  outputs =
    {
      self,
      nixpkgs,
      NixOS-WSL,
      nvf,
    }:
    {
      nixosConfigurations."nixos" = nixpkgs.lib.nixosSystem {
        system = "x86_64-linux";
        modules = [
          { nix.registry.nixpkgs.flake = nixpkgs; }
          nvf.nixosModules.default
          ./configuration.nix
          NixOS-WSL.nixosModules.wsl
        ];
      };
    };
}
