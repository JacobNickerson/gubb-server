{ config, lib, ... }:
let
  cfg = config.myModules.opencloud;
in
{
  options.myModules.opencloud = {
    enable = lib.mkEnableOption "Self-hosted file cloud configuration";
    port = lib.mkOption {
      type = lib.types.port;
      default = 9200;
    };
    dataDir = lib.mkOption {
      type = lib.types.path;
      default = "/var/lib/opencloud";
    };
  };

  config = lib.mkIf cfg.enable {
    services.opencloud = {
      enable = true;
      address = if (lib.attrByPath [ "myModules" "proxy" "services" "opencloud" "nginx" "enable" ] false config) then "127.0.0.1" else "0.0.0.0";
      port = cfg.port;
      url = "https://opencloud.${config.myModules.domain}";
      settings = {};
      stateDir = cfg.dataDir;
      environment = {
        PROXY_TLS = "false";
        IDM_ADMIN_PASSWORD="secure-password";
      };
    };

    sops.secrets."opencloud/cloudflare_token" = {};
    sops.secrets."opencloud/cloudflare_tunnel_id" = {};
    sops.secrets."opencloud/cloudflare_account_id" = {};
    sops.templates."opencloud-cloudflare.json" = {
      content = builtins.toJSON {
        AccountTag = config.sops.placeholder."opencloud/cloudflare_account_id";
        TunnelSecret = config.sops.placeholder."opencloud/cloudflare_token";
        TunnelID = config.sops.placeholder."opencloud/cloudflare_tunnel_id";
        Endpoint = "";
      };
    };

    myModules.proxy.services.opencloud = {
      port = cfg.port;
      dns.enable = true;
      nginx = {
        enable = true;
        enableACME = true;
        dontForceSSL = true;
        proxyWebsockets = true;
        extraConfig = ''
          client_max_body_size 0;
          proxy_set_header X-Forwarded-Proto $http_x_forwarded_proto;
        '';
      };
      cloudflare_tunnel = {
        enable = true;
        useHttpBoilerplate = true;
        credentialsFile = config.sops.templates."opencloud-cloudflare.json".path;
      };
    };

    myModules.homepage-dashboard.services.opencloud = {
      enable = true;
      name = "OpenCloud";
      description = "Local File Cloud";
      category = "files";
    };
  };
}