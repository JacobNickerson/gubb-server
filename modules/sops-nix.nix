{ config, lib, pkgs, ... }:
let
  cfg = config.myModules.sops-nix;
in
{
  options.myModules.sops-nix = {
    enable = lib.mkEnableOption "sops-nix secret management";

    defaultSopsFile = lib.mkOption {
      type = lib.types.nullOr lib.types.path;
      default = null;
      description = "Default SOPS secrets file";
    };

    ageKeyFile = lib.mkOption {
      type = lib.types.str;
      default = "/var/lib/sops-nix/key";
      description = "Path to the age key used to decrypt SOPS secrets";
    };
  };

  config = lib.mkIf cfg.enable {
    sops = lib.optionalAttrs (cfg.defaultSopsFile != null) {
      defaultSopsFile = cfg.defaultSopsFile;
    } // {
      age = {
        keyFile = cfg.ageKeyFile;
        generateKey = true;
      };
    };

    environment.systemPackages = with pkgs; [
      age
      sops
    ];
  };
}
