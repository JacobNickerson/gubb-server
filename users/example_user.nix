{ inputs, config, pkgs, ... }: let
  user_name = "USER_NAME_HERE";
	home_dir = "/home/${user_name}";
  flake_path = "FLAKE_PATH_HERE";  # NOTE: Does not need to be set for users that won't change system config
	imports = [

	];
in {
	config.users.users.USER_NAME_HERE = {
		isNormalUser = true;
		description = "DESC_HERE";
		extraGroups = [ ];
		shell = pkgs.bash;
		packages = with pkgs; [ ];
	};
	config.home-manager.users.USER_NAME_HERE = {
		inherit imports;
		fonts.fontconfig.enable = true;

		home = {
			username = user_name;
			homeDirectory = home_dir;
			stateVersion = "25.11"; 

			packages = with pkgs; [
				
			];

			sessionVariables = {

			};

			shellAliases = {

			};
		};

		services = {

		};

		programs = {
			home-manager.enable = true;
		};
	};
}
