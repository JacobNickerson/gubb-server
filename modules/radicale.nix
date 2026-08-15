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

    sops.secrets.radicale = {
      owner = "radicale";
      group = "radicale";
      mode = "0400";
    };

    services.radicale = {
      enable = true;

      settings = {
        server = {
          hosts = [ "127.0.0.1:${toString cfg.port}" ];
        };

        auth = {
          type = "htpasswd";
          htpasswd_filename = config.sops.secrets.radicale.path;
          htpasswd_encryption = "bcrypt";
        };

        storage = {
          filesystem_folder = collectionDir;
        };
      };
    };

    myModules.proxy.services.radicale = {
      port = cfg.port;
    };

    networking.firewall.allowedTCPPorts = [ cfg.port ];
  };
}