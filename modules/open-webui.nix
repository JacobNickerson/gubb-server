{ config, lib, ... }:
let
  cfg = config.myModules.open-webui;
in
{
  options.myModules.open-webui = {
    enable = lib.mkEnableOption "Open WebUI";
    port = lib.mkOption {
      type = lib.types.port;
      default = 3000; 
      example = 3000; 
    };
  };

  config = lib.mkIf cfg.enable {
    services.open-webui = {
      enable = true;
      host = "127.0.0.1";
      port = cfg.port;
      openFirewall = true;
      environmentFile = null; # TODO: Setup env file as needed
    };

    myModules.proxy.services.open-webui = {
      port = cfg.port;
      proxyWebsockets = true;
    };
  };
}
