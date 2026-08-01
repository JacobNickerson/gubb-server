{ config, lib, pkgs, ... }:
let
  cfg = config.myModules.dnsmasq;
in
{
  options.myModules.dnsmasq = {
    enable = lib.mkEnableOption "Dnsmasq service";
  };

	config = lib.mkIf cfg.enable {
		services.resolved.enable = false; # Listens on the same port as dnsmasq

		services.dnsmasq = {
			enable = true;
			alwaysKeepRunning = true;
			settings = {
				no-resolv = true;
				server = [
					"1.1.1.1"
					"8.8.8.8"
				];

				domain = config.myModules.domain;
				expand-hosts = true;
				local = "/${config.myModules.domain}/";

				# NOTE: Entries are defined per-service in their respective modules
			};
		};
		networking.firewall.allowedUDPPorts = [ 53 ];
	};
}