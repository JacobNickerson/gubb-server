{ config, pkgs, lib, ... }:

let
  cfg = config.myModules.kavita;
  dataDir = "/srv/kavita";
in
{
  options.myModules.kavita = {
    enable = lib.mkEnableOption "Self-hosted reading server";

    port = lib.mkOption {
      type = lib.types.int;
      default = 5000;
      description = "Port for the Kavita server to listen on";
    };

    create-library = lib.mkOption {
      type = lib.types.nullOr lib.types.str;
      default = null;
      description = "If not null, creates a directory owned by the kavita user";
    };

    allow-nas = lib.mkOption {
      type = lib.types.bool;
      default = false;
      description = "Whether the kavita user needs NAS permissions";
    };
  };

  config = lib.mkIf cfg.enable {
    systemd.tmpfiles.rules = [
      "d ${dataDir} 0750 kavita kavita -"
    ]
    ++ lib.optionals (cfg.create-library != null) 
    [ "d ${cfg.create-library} 0770 kavita users -" ];

    users.users.kavita = {
      isSystemUser = true;
      group = "kavita";
    };
    users.groups.kavita = {};
    users.users.kavita.extraGroups = lib.mkIf cfg.allow-nas [ "smb" ];

    sops.secrets."kavita/token" = {};

    services.kavita = {
      enable = true;

      user = "kavita";
      dataDir = dataDir;
      tokenKeyFile = config.sops.secrets."kavita/token".path;

      settings = {
        Port = cfg.port;
      };
    };

    networking.firewall.allowedTCPPorts = [ cfg.port ];
  };
}