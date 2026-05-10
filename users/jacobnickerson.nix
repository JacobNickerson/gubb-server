{ inputs, config, pkgs, ... }: let
  user_name = "jacobnickerson";
	home_dir = "/home/${user_name}";
  flake_path = "${home_dir}/gubb-server";
	imports = [
		./modules/git.nix
		./modules/neovim.nix
		(import ./modules/nix-helper.nix { flake_path = flake_path; })
		./modules/tmux.nix
		./modules/zsh.nix
	];
in {
	config.users.users.jacobnickerson = {
		isNormalUser = true;
		description = "Jacob Nickerson";
		extraGroups = [ "networkmanager" "wheel" "smb" ];
		shell = pkgs.zsh;
		ignoreShellProgramCheck = true; # NOTE: Silences a warning about shell not being enabled
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
				lg   = "eza -alg --color=always --group-directories-first --icons";
				ldot = "eza -a | grep -e '^\\.'";
				dev         = "nix develop --command zsh";
				tmp         = "nix-shell --command zsh -p";
				tarnow      = "tar -acf ";
				untar       = "tar -zxvf ";
				wget        = "wget -c ";
				psmem       = "ps auxf | sort -nr -k 4";
				psmem10     = "ps auxf | sort -nr -k 4 | head -10";
				dir         = "dir --color=auto";
				vdir        = "vdir --color=auto";
				grep        = "grep --color=auto";
				jctl        = "journalctl -p 3 -xb";
			};
		};

		services = {

		};

		programs = {
			home-manager.enable = true;
		};
	};
}
