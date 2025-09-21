{
  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    NixOS-WSL = {
      url = "github:nix-community/NixOS-WSL/main";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    my-nvim = {
      url = "github:Jeomhps/nvf-vim";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };
  outputs = {
    nixpkgs,
    NixOS-WSL,
    ...
  } @ inputs: {
    nixosConfigurations."nixos" = nixpkgs.lib.nixosSystem {
      system = "x86_64-linux";
      modules = [
        {nix.registry.nixpkgs.flake = nixpkgs;}
        ./configuration.nix
        NixOS-WSL.nixosModules.wsl
      ];
      specialArgs = {inherit inputs;};
    };
  };
}
