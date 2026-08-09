{ config, lib, pkgs, ... }:
let
  cfg = config.myModules.proxy;
in
{
	options.myModules.proxy = {
		enable = lib.mkEnableOption "DNS + Reverse proxy services";

		services = lib.mkOption {
			type = lib.types.attrsOf (lib.types.submodule ({ name, ... }: {
				options = {
					port = lib.mkOption {
						type = lib.types.port;
						description = "Local port the service listens on";
					};
					proxyWebsockets = lib.mkOption {
						type = lib.types.bool;
						default = false;
						description = "Enable WebSocket proxying (proxy_http_version 1.1 + Upgrade headers)";
					};
					extraConfig = lib.mkOption {
						type = lib.types.lines;
						default = "";
						description = ''
							Extra configuration lines added to the nginx virtualHost.
							Useful for things like client_max_body_size, timeouts, etc.
						'';
						example = ''
							client_max_body_size 5000M;
						'';
					};
				};
      }));
      default = {};
      description = "Services that should be exposed via dnsmasq + nginx reverse proxy";
    };
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
			};
		};

		services.nginx = {
			enable = true;

			recommendedProxySettings = true;
			recommendedTlsSettings = true;
			recommendedGzipSettings = true;
		};

		networking.firewall.allowedTCPPorts = [ 80 443 ];
		networking.firewall.allowedUDPPorts = [ 53 ];

		services.dnsmasq.settings.address = lib.mkAfter (
			lib.mapAttrsToList
			(name: svc: "/${name}.${config.myModules.domain}/${config.myModules.server_address}")
			cfg.services
		);

    services.nginx.virtualHosts = lib.mapAttrs'
      (name: svc: {
        name = "${name}.${config.myModules.domain}";
        value = {
          locations."/" = {
            proxyPass = "http://127.0.0.1:${toString svc.port}";
            recommendedProxySettings = true;
						proxyWebsockets = svc.proxyWebsockets;
						extraConfig = svc.extraConfig;
          };
        };
      })
      cfg.services;
	};
}