{ inputs, config, pkgs, ... }: let
  user_name = "slyniashi";
	home_dir = "/home/${user_name}";
  flake_path = "";
	imports = [

	];
in {
	config.users.users.slyniashi = {
		isNormalUser = true;
		description = "Slynia Shi";
		extraGroups = [ "smb" ];
		shell = pkgs.bash;
		packages = with pkgs; [ ];
	};
	config.home-manager.users.slyniashi = {
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
