{ config, lib, pkgs, ... }:
let
  cfg = config.myModules.frigate;
  dataDir = "/srv/frigate";
  hostname = "localhost";
  secret = config.sops.placeholder;

  frigateSettings = {
    database.path = "${dataDir}/frigate.db";

    mqtt = {
      enabled = true;
      host = "192.168.5.33";
      user = "frigate";
      password = "{FRIGATE_MQTT_PASS}";
    };

    cameras = {
      a_cam = {
        ffmpeg.inputs = [
          {
            path = "rtsp://127.0.0.1:8554/a_cam";
            input_args = "preset-rtsp-restream";
            roles = [ "record" "audio" ];
          }
          {
            path = "rtsp://{FRIGATE_A_USER}:{FRIGATE_A_PASS}@192.168.7.1:554/stream2";
            input_args = "preset-rtsp-generic";
            roles = [ "detect" ];
          }
        ];

        onvif = {
          host = "192.168.7.1";
          port = 2020;
          user = "{FRIGATE_A_USER}";
          password = "{FRIGATE_A_PASS}";
        };

        detect = {
          width = 640;
          height = 360;
          fps = 5;
        };

        record.enabled = false;
        snapshots.enabled = true;
      };

      z_cam = {
        ffmpeg.inputs = [
          {
            path = "rtsp://127.0.0.1:8554/z_cam";
            input_args = "preset-rtsp-restream";
            roles = [ "record" "audio" ];
          }
          {
            path = "rtsp://{FRIGATE_Z_USER}:{FRIGATE_Z_PASS}@192.168.7.2:554/stream2";
            input_args = "preset-rtsp-generic";
            roles = [ "detect" ];
          }
        ];

        onvif = {
          host = "192.168.7.2";
          port = 2020;
          user = "{FRIGATE_Z_USER}";
          password = "{FRIGATE_Z_PASS}";
        };

        detect = {
          width = 640;
          height = 360;
          fps = 5;
        };

        record.enabled = false;
        snapshots.enabled = true;
      };
    };
  };

  go2rtcSettings = {
    streams = {
      a_cam = [
        "rtsp://\${FRIGATE_A_USER}:\${FRIGATE_A_PASS}@192.168.7.1:554/stream1"
      ];

      z_cam = [
        "rtsp://\${FRIGATE_Z_USER}:\${FRIGATE_Z_PASS}@192.168.7.2:554/stream1"
      ];
    };
  };
in
{
  options.myModules.frigate = {
    enable = lib.mkEnableOption "Frigate NVR";
  };

  config = lib.mkIf cfg.enable {
    systemd.tmpfiles.rules = [
      "d ${dataDir} 0750 frigate frigate -"
    ];

    sops.secrets."frigate/a_user" = {};
    sops.secrets."frigate/a_pass" = {};
    sops.secrets."frigate/z_user" = {};
    sops.secrets."frigate/z_pass" = {};
    sops.secrets."frigate/mqtt_pass" = {};

    sops.templates."frigate.env" = {
      content = ''
        FRIGATE_A_USER="${secret."frigate/a_user"}"
        FRIGATE_A_PASS="${secret."frigate/a_pass"}"
        FRIGATE_Z_USER="${secret."frigate/z_user"}"
        FRIGATE_Z_PASS="${secret."frigate/z_pass"}"
        FRIGATE_MQTT_PASS="${secret."frigate/mqtt_pass"}"
      '';
      mode = "0400";
      restartUnits = [
        "frigate.service"
        "go2rtc.service"
      ];
    };

    services.frigate = {
      enable = true;
      hostname = hostname;
      checkConfig = false;
      settings = frigateSettings;
    };

    services.go2rtc = {
      enable = true;
      settings = go2rtcSettings;
    };

    systemd.services.frigate = {
      after = [ "sops-install-secrets.service" ];
      wants = [ "sops-install-secrets.service" ];
      serviceConfig.EnvironmentFile = config.sops.templates."frigate.env".path;
    };

    systemd.services.go2rtc = {
      after = [ "sops-install-secrets.service" ];
      wants = [ "sops-install-secrets.service" ];
      serviceConfig.EnvironmentFile = config.sops.templates."frigate.env".path;
    };

    networking.firewall.allowedTCPPorts = [ 42367 ];
    services.nginx.virtualHosts."frigate.lan" = {
      listen = [
        {
          addr = "0.0.0.0";
          port = 42367;
        }
      ];
      forceSSL = false;
      locations."/" = {
        proxyPass = "http://127.0.0.1:5000";
        proxyWebsockets = true;
      };
    };
  };
}