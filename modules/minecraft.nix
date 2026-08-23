{ config, lib, pkgs, ... }:
let
  cfg = config.myModules.minecraft;

  sizeToBytes = s:
    let
      m = builtins.match "^([0-9]+)([KMGkmg])$" s;
      n = builtins.fromJSON (builtins.elemAt m 0);
      unit = builtins.elemAt m 1;
      multiplier =
        if unit == "K" || unit == "k" then 1024
        else if unit == "M" || unit == "m" then 1024 * 1024
        else 1024 * 1024 * 1024;
    in
      n * multiplier;
in
{
  options.myModules.minecraft = {
    enable = lib.mkEnableOption "A template for a new module";
    port = lib.mkOption {
      type = lib.types.port; 
      default = 25565;
      description = "Port to listen on";
    }; 
    initMem = lib.mkOption {
      type = lib.types.strMatching "^[0-9]+[KMGkmg]$";
      default = "1G";
      description = "Memory (in GiB) acquired by the JVM at init";
      example = "512M";
    };
    maxMem = lib.mkOption {
      type = lib.types.strMatching "^[0-9]+[KMGkmg]$";
      default = "4G";
      description = "Memory limit (in GiB) for the JVM";
      example = "4G";
    };
  };

  config = lib.mkIf cfg.enable {
    assertions = [
      {
        assertion = (sizeToBytes cfg.initMem) <= (sizeToBytes cfg.maxMem);
        message = "initMem must be less than or equal to maxMem";
      }
    ];
    services.minecraft-server = {
      enable = true;

      package = pkgs.minecraftServers.vanilla-1-21;

      jvmOpts = "-Xms${cfg.initMem} -Xmx${cfg.maxMem}";

      declarative = true;

      eula = true;
      serverProperties = {
        server-port = cfg.port;
        motd = "Hello World!";

        gamemode = "survival";
        difficulty = "hard";

        max-players = 10;
        online-mode = true;
        white-list = false;

        enable-command-block = false;
        view-distance = 10;
        simulation-distance = 10;

        pvp = true;
        spawn-protection = 16;
      };
    };

    networking.firewall.allowedTCPPorts = [ cfg.port ];

    myModules.proxy.services.mc = {
      dns.enable = true;
    };
  };
}