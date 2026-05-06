{ config, pkgs, ... }:
{
	users.users.jacobnickerson = {
		isNormalUser = true;
		description = "Jacob Nickerson";
		extraGroups = [ "networkmanager" "wheel" ];
		packages = with pkgs; [];
	};
}
