{ config, lib, ... }:
let
  cfg = config.myModules.nginx;
in
{
  options.myModules.nginx = {
    enable = lib.mkEnableOption "Nginx reverse proxy service";
  };

  config = lib.mkIf cfg.enable {
    services.nginx = {
      enable = true;

      recommendedProxySettings = true;
      recommendedTlsSettings = true;
      recommendedGzipSettings = true;
    };

    networking.firewall.allowedTCPPorts = [
      80
      443
    ];
  };
}