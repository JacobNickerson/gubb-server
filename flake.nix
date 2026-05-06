{
  description = "GubbServer Configuration";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-25.11";
  };

  outputs = { nixpkgs, ... }@inputs:
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
        ] ++ users;
      };  
  in {
    nixosConfigurations = {
      GubbServer = mkHost {
        hostname = "GubbServer";
        config = ./configuration.nix;
	hostConfig = ./host-configuration.nix;
        users = [ ./users/jacobnickerson.nix ];
      };
    };
  };
}
