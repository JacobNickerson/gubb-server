{ config, lib, ... }:
let
  cfg = config.myModules.searxng;
in
{
  options.myModules.searxng = {
    enable = lib.mkEnableOption "SearXNG self-hosted AI web search provider";
    port = lib.mkOption {
      type = lib.types.port;
      default = 8888; 
      example = 8888; 
    };
  };

  config = lib.mkIf cfg.enable {
    sops.secrets."searxng/api_key" = {};
    sops.templates."searxng.env" = {
      content = ''
        SEARXNG_SECRET=${config.sops.placeholder."searxng/api_key"}
      '';
      mode = "0400";
    };


    services.searx = {
      enable = true;
      
      environmentFile = config.sops.templates."searxng.env".path;

      redisCreateLocally = true;

      settings = {
        use_default_settings = true;

        general = {
          debug = false;
          instance_name = "SearXNG";
          donation_url = false;
          contact_url = false;
          privacypolicy_url = false;
          enable_metrics = false;
        };

        server = {
          bind_address = "127.0.0.1";
          port = cfg.port;
          base_url = "https://search.knitnet.org/";
          image_proxy = true;
          public_instance = false;
        };

        search = {
          safe_search = 0;
          autocomplete = "duckduckgo";
          formats = [
            "html"
            "json"
          ];
        };

        ui = {
          default_theme = "simple";
          theme_args.simple_style = "auto";
        };
      };
    };

    myModules.proxy.services.searxng = {
      port = cfg.port;
      dns.enable = true;
      nginx = {
        enable = true;
        enableACME = true;
      };
    };
  };
}