{
  description = "GubbServer Configuration";

  inputs = {
    home-manager = {
    	url = "github:nix-community/home-manager";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";
    vscode-server.url = "github:nix-community/nixos-vscode-server";
  };

  outputs = { nixpkgs, home-manager, vscode-server, ... }@inputs:
  let
    system = "x86_64-linux";

    pkgs = import nixpkgs {
      inherit system;
      config.allowUnfree = true;
      overlays = [ ];
    };

    mkHost = { hostname, config, hostConfig, users ? [] }:
      nixpkgs.lib.nixosSystem {
        inherit system pkgs;
        specialArgs = { inherit inputs; };
        modules = [
          ({ ... }: { networking.hostName = hostname; })
          config
          hostConfig
          home-manager.nixosModules.home-manager
          {
            home-manager.useGlobalPkgs = true;
            home-manager.useUserPackages = true;
            home-manager.extraSpecialArgs = { inherit inputs; hostname = hostname; };
          }
          vscode-server.nixosModules.default
        ] ++ users;
      };  
  in {
    nixosConfigurations = {
      GubbServer = mkHost {
        hostname = "GubbServer";
        config = ./configuration.nix;
        hostConfig = ./host-configuration.nix;
        users = [
          ./users/jacobnickerson.nix
          ./users/slyniashi.nix
        ];
      };
    };
  };
}