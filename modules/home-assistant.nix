{ config, lib, pkgs, ... }:
let
  cfg = config.myModules.home-assistant;
  port = 8123;
in
{
  options.myModules.home-assistant = {
    enable = lib.mkEnableOption "Home Assistant";
  };

  config = lib.mkIf cfg.enable {
    services.home-assistant = {
      enable = true;
      extraComponents = [
        # Components required to complete the onboarding
        "analytics"
        "google_translate"
        "met"
        "radio_browser"
        "shopping_list"
        # Recommended for fast zlib compression
        # https://www.home-assistant.io/integrations/isal
        "isal"
        "mqtt"
      ];
      customComponents = [
        pkgs.home-assistant-custom-components.frigate
      ];
      config = {
        # Includes dependencies for a basic setup
        # https://www.home-assistant.io/integrations/default_config/
        default_config = {};
        mqtt = {};
        #http = {
        #  use_x_forwarded_for = true;
        #  trusted_proxies = [ "127.0.0.1" ];
        #};
      };
    };
    
    networking.firewall.allowedTCPPorts = [ port ];

    myModules.proxy.services.home-assistant = {
      port = port;
      dns.enable = true;
      nginx = {
        enable = true;
        enableACME = true;
        proxyWebsockets = true;
      };
    };

    myModules.homepage-dashboard.services.home-assistant = {
      enable = true;
      name = "Home Assistant";
      description = "Home Automation Center";
      category = "home";
    };
  };
}
