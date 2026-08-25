{ config, lib, pkgs, ... }:
let
  cfg = config.myModules.homepage-dashboard;
in
{
  options.myModules.homepage-dashboard = {
    enable = lib.mkEnableOption "Homepage dashboard with service widgets";
    port = lib.mkOption {
      type = lib.types.port;
      default = 3000;
    };
    services = lib.mkOption {
      type = lib.types.attrsOf (lib.types.submodule ({ name, ... }: {
        options = {
          enable = lib.mkEnableOption "Add a widget for this service";

          name = lib.mkOption {
            type = lib.types.nullOr lib.types.str;
            default = null;
            description = "Display name for the service card";
          };
          
          description = lib.mkOption {
            type = lib.types.str;
            default = "configure me!";
            description = "Description of the service";
          };

          category = lib.mkOption {
            type = lib.types.str;
            default = "other";
            description = "Category to list this service under";
          };

          extraSettings = lib.mkOption {
            type = lib.types.attrs;
            default = {};
            description = "Extra settings for the widget";
            example = {

            };
          };
        };
      }));
      default = {};
      description = "Services to add as widgets to the homepage dashboard";
    };
  };

  config = lib.mkIf cfg.enable {
    services.homepage-dashboard = {
      enable = true;
      listenPort = cfg.port;
      openFirewall = true;

      allowedHosts = "dashboard.${config.myModules.domain}";

      # widgets = lib.mapAttrsToList (name: svc: {
      #   "${name}" = {
      #     icon = iconToUrl svc.icon;
      #     url = "${if config.myModules.proxy.services.${name}.nginx.dontForceSSL then "http" else "https"}://${name}.${config.myModules.domain}";
      #   };
      # }) (lib.filterAttrs (_name: svc: svc.enable == true) cfg.services);

      settings = {
        title = "Home";
      };

      services = [
        {
          "Home" = (lib.mapAttrsToList (name: svc: {
            "${if svc.name != null then svc.name else name}" = {
              href = "https://${name}.${config.myModules.domain}";
              description = svc.description;
              # icon = svc.icon;
              extraSettings = svc.extraSettings;
            };
          }) (lib.filterAttrs (_name: svc: svc.enable == true && svc.category == "home") cfg.services));
        }
        {
          "Files" = (lib.mapAttrsToList (name: svc: {
            "${if svc.name != null then svc.name else name}" = {
              href = "https://${name}.${config.myModules.domain}";
              description = svc.description;
              # icon = svc.icon;
              extraSettings = svc.extraSettings;
            };
          }) (lib.filterAttrs (_name: svc: svc.enable == true && svc.category == "files") cfg.services));
        }
        {
          "Other" = (lib.mapAttrsToList (name: svc: {
            "${if svc.name != null then svc.name else name}" = {
              href = "https://${name}.${config.myModules.domain}";
              description = svc.description;
              # icon = svc.icon;
              extraSettings = svc.extraSettings;
            };
          }) (lib.filterAttrs (_name: svc: svc.enable == true && svc.category != "files" && svc.category != "home") cfg.services));
        }
      ];
    };

    sops.secrets."dashboard/cloudflare_token" = {};
    sops.secrets."dashboard/cloudflare_tunnel_id" = {};
    sops.secrets."dashboard/cloudflare_account_id" = {};
    sops.templates."dashboard-cloudflare.json" = {
      content = builtins.toJSON {
        AccountTag = config.sops.placeholder."dashboard/cloudflare_account_id";
        TunnelSecret = config.sops.placeholder."dashboard/cloudflare_token";
        TunnelID = config.sops.placeholder."dashboard/cloudflare_tunnel_id";
        Endpoint = "";
      };
    };

    myModules.proxy.services.dashboard = {
      port = cfg.port;
      dns.enable = true;
      nginx = {
        enable = true;
        enableACME = true;
        dontForceSSL = true;
      };
      cloudflare_tunnel = {
        enable = true;
        useHttpBoilerplate = true;
        credentialsFile = config.sops.templates."dashboard-cloudflare.json".path;
      };
    };
  };
}