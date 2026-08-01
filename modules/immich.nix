{ config, pkgs, lib, ... }:
let
  cfg = config.myModules.immich;
  dataDir = "/srv/immich";
  uploadDir = "${dataDir}/storage";

  dbName = "immich";
  dbUser = "immich";
in
{
  options.myModules.immich = {
    enable = lib.mkEnableOption "Immich server";

    port = lib.mkOption {
      type = lib.types.int;
      default = 42267;
      description = "Port for the Immich server";
    };
  };

  config = lib.mkIf cfg.enable {
    systemd.tmpfiles.rules = [
      "d ${dataDir} 0750 immich immich -"
      "d ${uploadDir} 0750 immich immich -"
    ];

    services.dnsmasq.settings.address = lib.mkAfter [
      "/immich.${config.myModules.domain}/${config.myModules.server_address}"
    ];

    services.nginx.virtualHosts = {
      "immich.${config.myModules.domain}" = {
        locations."/" = {
          proxyPass = "http://127.0.0.1:${toString cfg.port}";
          extraConfig = ''
            client_max_body_size 0;
          '';
        };
      };
    };

    services.immich = {
      enable = true;

      user = "immich";
      group = "immich";

      port = cfg.port;
      host = "127.0.0.1";
      openFirewall = true;

      mediaLocation = uploadDir;

      #accelerationDevices = null;

      redis.enable = true;

      database = {      # Recommended defaults
        enable = true;
        createDB = true;
        name = dbName;
        user = dbUser;
      };

      machine-learning.enable = false;
    };

    ##########################################################################
    # Optional Hardware Acceleration
    ##########################################################################
    # Intel Quick Sync:
    # users.users.immich.extraGroups = [ "video" "render" ];
    # hardware.graphics.enable = true;
    #
    # NVIDIA:
    # users.users.immich.extraGroups = [ "video" "render" ];
    # hardware.nvidia-container-toolkit.enable = true;
    #
    # AMD VAAPI:
    # users.users.immich.extraGroups = [ "video" "render" ];
    # hardware.graphics.enable = true;

    ##########################################################################
    # Optional Mount for Photo Library
    ##########################################################################
    # To import photos from an existing read-only library:
    #
    # fileSystems."/mnt/photo-library" = {
    #   device = "/dev/disk/by-uuid/XXXXXXXX-XXXX";
    #   fsType = "ext4";
    #   options = [ "ro" "nofail" ];
    # };
    #
    # Then add the path as an External Library in the Immich web UI.

    ##########################################################################
    # Backup Recommendations
    ##########################################################################
    # Back up:
    # - ${uploadDir}
    # - PostgreSQL database (${dbName})
    # - Machine learning cache (optional, can be regenerated)
    #
    # Example PostgreSQL dump:
    #   sudo -u postgres pg_dump ${dbName} > immich.sql
  };
}