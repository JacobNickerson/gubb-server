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
  };

  config = lib.mkIf cfg.enable {
    systemd.tmpfiles.rules = [
      "d ${dataDir} 0750 immich immich -"
      "d ${uploadDir} 0750 immich immich -"
    ];

    services.immich = {
      enable = true;

      user = "immich";
      group = "immich";

      port = 42267;
      host = "0.0.0.0";
      openFirewall = true;

      mediaLocation = uploadDir;

      #accelerationDevices = null;

      redis.enable = true;

      database = {
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
