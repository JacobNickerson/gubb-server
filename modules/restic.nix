{ config, lib, pkgs, ... }:
let
  cfg = config.myModules.restic;
in
{
  options.myModules.restic = {
    enable = lib.mkEnableOption "Restic backup service";

    repo = lib.mkOption {
      type = lib.types.str;
      description = "Repository to store backups on";
    };
  };

  config = lib.mkIf cfg.enable {
    services.restic.backups.srv-backup = {
      initialize = true;
      repository = cfg.repo;
      passwordFile = "/etc/restic-passwd";   # <passwd>
      environmentFile = "/etc/restic-env";   # B2_ACCOUNT_ID=<keyid>
                                             # B2_ACCOUNT_KEY=<appkey>

      paths = [ "/srv" ];

      timerConfig = {
        OnCalendar = "daily";
        Persistent = true;
      };
    };

    environment.systemPackages = with pkgs; [
      restic
    ];
  };
}
