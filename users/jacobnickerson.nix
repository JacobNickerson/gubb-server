{ inputs, config, pkgs, ... }: let
  user_name = "jacobnickerson";
	home_dir = "/home/${user_name}";
  flake_path = "${home_dir}/gubb-server";
	imports = [
		./modules/fish.nix
		./modules/git.nix
		./modules/neovim.nix
		(import ./modules/nix-helper.nix { flake_path = flake_path; })
		./modules/tmux.nix
	];
in {
	config.users.users.jacobnickerson = {
		isNormalUser = true;
		description = "Jacob Nickerson";
		extraGroups = [ "networkmanager" "wheel" "smb" ];
		shell = pkgs.fish;
		packages = with pkgs; [];
	};
	config.home-manager.users.jacobnickerson = {
		inherit imports;
		fonts.fontconfig.enable = true;

		home = {
			username = user_name;
			homeDirectory = home_dir;
			stateVersion = "25.11"; 

			packages = with pkgs; [
				eza
			];

			sessionVariables = {
				EDITOR = "nvim";
				VISUAL = "nvim";
			};

			shellAliases = {
				ls   = "eza -al --color=always --group-directories-first --icons";
				la   = "eza -a --color=always --group-directories-first --icons";
				ll   = "eza -l --color=always --group-directories-first --icons";
				lt   = "eza -aT --color=always --group-directories-first --icons";
				ldot = "eza -a | grep -e '^\\.'";
				dev         = "nix develop --command fish";
				tmp         = "nix-shell --command fish -p";
				tarnow      = "tar -acf ";
				untar       = "tar -zxvf ";
				wget        = "wget -c ";
				psmem       = "ps auxf | sort -nr -k 4";
				psmem10     = "ps auxf | sort -nr -k 4 | head -10";
				dir         = "dir --color=auto";
				vdir        = "vdir --color=auto";
				grep        = "grep --color=auto";
				fgrep       = "fgrep --color=auto";
				egrep       = "egrep --color=auto";
				hw          = "hwinfo --short";
				big         = "expac -H M '%m\t%n' | sort -h | nl";
				jctl        = "journalctl -p 3 -xb";
				rip         = "expac --timefmt='%Y-%m-%d %T' '%l\t%n %v' | sort | tail -200 | nl";
			};
		};

		services = {

		};

		programs = {
			home-manager.enable = true;
		};
	};
}
