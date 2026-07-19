{
  description = "GubbServer Configuration";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";
    home-manager = {
    	url = "github:nix-community/home-manager";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    jake-flake = {
      url = "github:jacobnickerson/nix-config";
      inputs.nixpkgs.follows = "nixpkgs";
      inputs.home-manager.follows = "home-manager";
    };
    sops-nix = {
      url = "github:Mic92/sops-nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    vscode-server.url = "github:nix-community/nixos-vscode-server";

    # NOTE: Temporary overlay, until this lands in nixpkgs-unstable
    frigate-fix.url = "github:NixOS/nixpkgs/00d642560bd1d2daf9939eb710c552d5dcddd737";
  };

  outputs = { nixpkgs, home-manager, vscode-server, sops-nix, frigate-fix, jake-flake, ... }@inputs:
  let
    system = "x86_64-linux";

    frigate-overlay = final: prev: {
      frigate = frigate-fix.legacyPackages.${system}.frigate;
    };

    pkgs = import nixpkgs {
      inherit system;
      config.allowUnfree = true;
      overlays = [ frigate-overlay ];
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
            home-manager.sharedModules = [ jake-flake.homeModules.default ];
          }
          sops-nix.nixosModules.sops
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