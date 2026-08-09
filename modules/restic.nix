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
    sops.secrets."restic/passwd" = {};
    sops.secrets."restic/account_id" = {};
    sops.secrets."restic/account_key" = {};

    sops.templates."restic.env".content = ''
      B2_ACCOUNT_ID=${config.sops.placeholder."restic/account_id"}
      B2_ACCOUNT_KEY=${config.sops.placeholder."restic/account_key"}
    '';

    services.restic.backups.srv-backup = {
      initialize = true;
      repository = cfg.repo;
      passwordFile = config.sops.secrets."restic/passwd".path;
      environmentFile = config.sops.templates."restic.env".path; 

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
