{ config, lib, pkgs, ... }:
let
  cfg = config.myModules.duck-dns;
in
{
  options.myModules.duck-dns = {
    enable = lib.mkEnableOption "Automated updater for DuckDNS";

	domain = lib.mkOption {
		type = lib.types.str;
		description = "DuckDNS domain";
	};
  };

  config = lib.mkIf cfg.enable {
	sops.secrets."duck-dns/token" = {};

	systemd.services.duckdns = {
		description = "Update DuckDNS IP address";

		serviceConfig = {
			Type = "oneshot";
			LoadCredential = [
				"token:${config.sops.secrets."duck-dns/token".path}"
			];
		};

		path = with pkgs; [ curl ];

		script = ''
			TOKEN="$(<"$CREDENTIALS_DIRECTORY/token")"
			${pkgs.curl}/bin/curl -fsS \
			"https://www.duckdns.org/update?domains=${cfg.domain}&token=$TOKEN&ip="
		'';
	};

	systemd.timers.duckdns = {
		description = "Periodically update DuckDNS";
		wantedBy = [ "timers.target" ];

		timerConfig = {
			OnBootSec = "1min";
			OnUnitActiveSec = "5min";
			Unit = "duckdns.service";
		};
	};
  };
}