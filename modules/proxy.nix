{ config, lib, pkgs, ... }:
let
  cfg = config.myModules.proxy;

	use_acme = builtins.any (x: x.nginx.enableACME) (builtins.attrValues cfg.services);
in
{
	options.myModules.proxy = {
		enable = lib.mkEnableOption "DNS, nginx reverse-proxy, and cloudflare tunnel helpers";

		services = lib.mkOption {
			type = lib.types.attrsOf (lib.types.submodule ({ name, ... }: {
				options = {
					port = lib.mkOption {
						type = lib.types.port;
						description = "Local port the service listens on";
					};
					dns.enable = lib.mkEnableOption "Add a DNS entry for this service";
					nginx = lib.mkOption {
						type = lib.types.submodule {
							options = {
								enable = lib.mkEnableOption "Setup nginx reverse-proxying to this service";
								enableACME = lib.mkEnableOption "Enable automatic TLS certificate generation via ACME (Let's Encrypt)"; 
								dontForceSSL = lib.mkEnableOption "Don't automatically redirect :80 traffic to :443";
								proxyWebsockets = lib.mkEnableOption "Enable WebSocket proxying (proxy_http_version 1.1 + Upgrade headers)";
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
								extra = lib.mkOption {
									type = lib.types.attrs;
									default = {};
									description = ''
										Extra configuration added to the nginx virtualHost.
										Useful for things like defining additional routes.
									'';
									example = {
										locations."/static/" = {
											alias = "/var/lib/app/static/";
										};
									};
								};
							};
						};
						default = {};
						description = "";
					};
					cloudflare_tunnel = lib.mkOption {
						type = lib.types.submodule {
							options = {
								enable = lib.mkEnableOption "Expose this service using a cloudflare tunnel";
								credentialsFile = lib.mkOption {
									type = lib.types.path;
									description = "File path to a json credentials file containing the expected cloudflare values";
								};
								useHttpBoilerplate = lib.mkEnableOption "Provide typical HTTP service boilerplating";
								default = lib.mkOption {
									type = lib.types.nullOr lib.types.str;
									default = null;
									description = "Catch-all service if no ingress matches, overrides default set by useHttpBoilerplate";
									example = "http_status:404";
								};
								extra = lib.mkOption {
									type = lib.types.attrs;
									default = {};
									description = ''
										Extra configuration added to the cloudflare tunnel.
										Useful for things like defining ingress routes.
									'';
									example = {
										ingress = {
											"myservice.org" = "http://localhost:80";
										};
									};
								};
							};
						};
						default = {};
						description = "Helper for setting Cloudflare tunnels with useful defaults";
					};
				};
			}));
			default = {};
			description = "Services that should be exposed via dnsmasq + nginx reverse proxy";
		};
	};

	config = lib.mkIf cfg.enable {
		assertions = lib.mapAttrsToList (serviceName: service: {
			assertion = !service.cloudflare_tunnel.enable || (service.cloudflare_tunnel.useHttpBoilerplate || service.cloudflare_tunnel.default != null);

			message = "myModules.proxy.services.${serviceName}.cloudflare_tunnel must set default (or alternatively use the default value from useHttpBoilerplate)";
		}) cfg.services;

		services.resolved.enable = false; # Listens on the same port as dnsmasq

		sops.secrets."cloudflare/dns_token" = lib.mkIf use_acme {};
		sops.templates."cloudflare.env".content = lib.mkIf use_acme '' 
			CLOUDFLARE_DNS_API_TOKEN=${config.sops.placeholder."cloudflare/dns_token"}
		'';

		security.acme = lib.mkIf use_acme { # TODO: Make this configurable
			acceptTerms = true;
			defaults.email = "jacobmilesnickerson@gmail.com";
			certs."${config.myModules.domain}" = {
				domain = "*.${config.myModules.domain}";
				group = "nginx";
				dnsProvider = "cloudflare";
				dnsResolver = "1.1.1.1:53";
				environmentFile = config.sops.templates."cloudflare.env".path;
			};
		};

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

		services.cloudflared = {
			enable = true;
		};
		environment.systemPackages = with pkgs; [
			cloudflared
		];

		networking.firewall.allowedTCPPorts = [ 80 443 ];
		networking.firewall.allowedUDPPorts = [ 53 ];

		services.dnsmasq.settings.address = lib.mkAfter (
			lib.mapAttrsToList
			(name: _svc: "/${name}.${config.myModules.domain}/${config.myModules.server_address}")
			(lib.filterAttrs (_name: svc: svc.dns.enable == true) cfg.services)
		);

		services.nginx.virtualHosts = lib.mapAttrs' (name: svc: {
			name = "${name}.${config.myModules.domain}";
			value = lib.mkMerge [
				{
					serverName = "${name}.${config.myModules.domain}";
					useACMEHost = if svc.nginx.enableACME then config.myModules.domain else null;
					forceSSL = !svc.nginx.dontForceSSL;
					addSSL = svc.nginx.dontForceSSL;
					locations."/" = {
						proxyPass = "http://127.0.0.1:${toString svc.port}";
						recommendedProxySettings = true;
						proxyWebsockets = svc.nginx.proxyWebsockets;
						extraConfig = svc.nginx.extraConfig;
					};
				}
				svc.nginx.extra
			];
		}) (lib.filterAttrs (_name: svc: svc.nginx.enable == true) cfg.services);

		services.cloudflared.tunnels = lib.mapAttrs' (name: svc: {
			name = name;
			value =  (lib.mkMerge [
				{
					credentialsFile = svc.cloudflare_tunnel.credentialsFile;
					default = lib.mkIf (svc.cloudflare_tunnel.default != null) svc.cloudflare_tunnel.default;
				}
				(lib.mkIf svc.cloudflare_tunnel.useHttpBoilerplate {
					default = lib.mkDefault "http_status:404";
					ingress = {
						"${name}.${config.myModules.domain}" = "http://localhost:80"; # Points at nginx, rather than direct service
					};
					originRequest.httpHostHeader = "${name}.${config.myModules.domain}";
				})
				svc.cloudflare_tunnel.extra
			]);
		}) (lib.filterAttrs (_name: svc: svc.cloudflare_tunnel.enable == true) cfg.services);
	};
}
