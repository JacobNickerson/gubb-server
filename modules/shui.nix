{ config, lib, pkgs, ... }:
let
  cfg = config.myModules.shui;
  version = "0.1.0";
  shui-deps = [
    pkgs.python3Packages.django
    pkgs.python3Packages.python-dotenv
    pkgs.python3Packages.pillow
    pkgs.python3Packages.gunicorn
    pkgs.python3Packages.django-storages
    pkgs.python3Packages.django-cleanup
  ];
  shui-pkg = pkgs.python3Packages.buildPythonPackage {
    pname = "shui";
    version = version;
    pyproject = true;
    nativeBuildInputs = [
      pkgs.python3Packages.setuptools
      pkgs.python3Packages.wheel
    ];
    dependencies = shui-deps; 
    src = pkgs.fetchFromGitHub {
      owner = "JacobNickerson";
      repo = "shui";
      rev = "v${version}";
      hash = "sha256-kFRGFhglkfMBea3SuGnZbnTMFsQBsLWcwgVL+Jlos/0=";
    };
  };
  pythonEnv = pkgs.python3.withPackages (ps: [ shui-pkg ] ++ shui-deps);
  stateDir = "/var/lib/shui";
in
{
  options.myModules.shui = {
    enable = lib.mkEnableOption "Enable the Shui Inventory WebAPp";
    dataDir = lib.mkOption {
      type = lib.types.path;
      default = "/var/lib/shui";
      example = "/var/lib/shui";
    };
    port = lib.mkOption {
      type = lib.types.port;
      default = 8000;
      example = 8000;
    };
    allowedHosts = lib.mkOption {
      type = lib.types.str;
      default = "127.0.0.1";
    };
  };

  config = lib.mkIf cfg.enable {
    users.users.shui = {
      isSystemUser = true;
      group = "shui";
    };
    users.groups.shui = {};

    systemd.tmpfiles.rules = [
      "d ${cfg.dataDir} 0750 shui nginx -" # cursed
      "d ${stateDir} 0750 shui nginx -"
    ];

    sops.secrets."shui/secret_key" = {};
    sops.templates."shui.env" = {
      content = ''
        SECRET_KEY=${config.sops.placeholder."shui/secret_key"}
      '';
      mode = "0400";
    };

    sops.secrets."shui/cloudflare_token" = {};
    sops.secrets."shui/tunnel_id" = {};
    sops.secrets."shui/account_id" = {};
    sops.templates."shui-cloudflare.json" = {
      content = builtins.toJSON {
        AccountTag = config.sops.placeholder."shui/account_id";
        TunnelSecret = config.sops.placeholder."shui/cloudflare_token";
        TunnelID = config.sops.placeholder."shui/tunnel_id";
        Endpoint = "";
      };
    };

    systemd.services.shui-migrate = {
      description = "Run Django migrations and collect static files";
      wantedBy = [ "multi-user.target" ];
      environment = {
        ALLOWED_HOSTS = cfg.allowedHosts;
        SHUI_DATA_DIR = cfg.dataDir;
        SHUI_STATE_DIR = stateDir;
        HOME = stateDir;
        DJANGO_SETTINGS_MODULE = "shui.settings";
      };

      serviceConfig = {
        Type = "oneshot";
        User = "shui";
        Group = "shui";

        StateDirectory = "shui";

        EnvironmentFile = config.sops.templates."shui.env".path;

        ExecStart = pkgs.writeShellScript "shui-migrate" ''
          set -e
          ${pythonEnv}/bin/python -m django migrate --noinput
          ${pythonEnv}/bin/python -m django collectstatic --noinput
        '';
      };
    };

    systemd.services.shui = {
      description = "Shui Inventory WebApp";
      wantedBy = [ "multi-user.target" ];
      after = [ "network.target" "shui-migrate.service" ];
      requires = [ "shui-migrate.service" ];
      environment = {
        ALLOWED_HOSTS = cfg.allowedHosts;
        SHUI_DATA_DIR = cfg.dataDir;
        SHUI_STATE_DIR = stateDir;
        HOME = stateDir;
      };

      serviceConfig = {
        Type = "simple";

        ExecStart = "${pythonEnv}/bin/gunicorn shui.wsgi:application --bind 127.0.0.1:${toString cfg.port}";

        EnvironmentFile = config.sops.templates."shui.env".path;
        
        StateDirectory = "shui";

        Restart = "on-failure";
        RestartSec = 5;

        User = "shui";
        Group = "shui";
      };
    };

    networking.firewall.allowedTCPPorts = [ cfg.port ];

    myModules.proxy.services.shui = {
      port = cfg.port;
      dontForceSSL = true;
      extra = {
        locations."/static/" = {
          alias = "${stateDir}/staticfiles/";
        };
        locations."/media/" = {
          alias = "${cfg.dataDir}/media/";
        };
      };
    };

    services.cloudflared = {
      enable = true;
      tunnels."shui-tunnel" = {
        credentialsFile = config.sops.templates."shui-cloudflare.json".path;
        default = "http_status:404";
        ingress = {
          "shui.knitnet.org" = "http://localhost:80";
        };
        originRequest.httpHostHeader = "shui.knitnet.org";
      };
    };
  };
}