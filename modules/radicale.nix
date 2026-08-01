{ config, lib, ... }:
let
  cfg = config.myModules.radicale;
  dataDir = "/srv/radicale";
  collectionDir = "${dataDir}/collections";
in
{
  options.myModules.radicale = {
    enable = lib.mkEnableOption "CalDAV server";

    port = lib.mkOption {
      type = lib.types.int;
      default = 5232;
      description = "Port for the Radicale server";
    };
  };

  config = lib.mkIf cfg.enable {
    systemd.tmpfiles.rules = [
      "d ${dataDir} 0750 radicale radicale -"
      "d ${collectionDir} 0750 radicale radicale -"
    ];

    services.radicale = {
      enable = true;

      settings = {
        server = {
          hosts = [ "127.0.0.1:${toString cfg.port}" ];
        };

        auth = {
          type = "none"; # TODO: Add proper auth
          # htpasswd_filename = "${dataDir}/users";
          # htpasswd_encryption = "bcrypt";
        };

        storage = {
          filesystem_folder = collectionDir;
        };
      };
    };

    services.dnsmasq.settings.address = lib.mkAfter [
      "/radicale.${config.myModules.domain}/${config.myModules.server_address}"
    ];

    services.nginx.virtualHosts = {
      "radicale.${config.myModules.domain}" = {
        locations."/" = {
          proxyPass = "http://127.0.0.1:${toString cfg.port}";
        };
      };
    };

    networking.firewall.allowedTCPPorts = [ cfg.port ];
  };
}