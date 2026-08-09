{ config, lib, pkgs, ... }:
let
  cfg = config.myModules.frigate;
  frigateDir = "/srv/frigate";
  dataDir = "${frigateDir}/data";
  configDir = "${frigateDir}/config";
  hostname = "localhost";
  secret = config.sops.placeholder;

  frigateConfig = pkgs.formats.yaml { };

  frigateSettings = {
    mqtt = {
      enabled = true;
      host = config.myModules.server_address;
      user = "frigate";
      password = "{FRIGATE_MQTT_PASS}";
    };

    go2rtc = {
      streams = {
        a_cam = [
          "rtsp://{FRIGATE_A_USER}:{FRIGATE_A_PASS}@192.168.7.1:554/stream1"
          "ffmpeg:a_cam#af=volume=3.0"
        ];
        a_cam_alt = [
          "rtsp://{FRIGATE_A_USER}:{FRIGATE_A_PASS}@192.168.7.1:554/stream2"
          "ffmpeg:a_cam_alt#audio=aac#af=volume=3.0"
        ];

        z_cam = [
          "rtsp://{FRIGATE_Z_USER}:{FRIGATE_Z_PASS}@192.168.7.2:554/stream1"
          "ffmpeg:z_cam#af=volume=3.0"
        ];
        z_cam_alt = [
          "rtsp://{FRIGATE_Z_USER}:{FRIGATE_Z_PASS}@192.168.7.2:554/stream2"
          "ffmpeg:z_cam_alt#audio=aac#af=volume=3.0"
        ];
      };
      webrtc = {
        candidates = [
          "192.168.7.1:8555"
          "192.168.7.2:8555"
        ];
      };
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
            path = "rtsp://127.0.0.1:8554/a_cam_alt";
            input_args = "preset-rtsp-restream";
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

        audio.enabled = true;
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
            path = "rtsp://127.0.0.1:8554/z_cam_alt";
            input_args = "preset-rtsp-restream";
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

        audio.enabled = true;
        record.enabled = false;
        snapshots.enabled = true;
      };
    };
  };
in
{
  options.myModules.frigate = {
    enable = lib.mkEnableOption "Frigate NVR";

    port = lib.mkOption {
      type = lib.types.int;
      default = 5000;
      description = "Port for the Frigate web interface";
    };
  };

  config = lib.mkIf cfg.enable {
    users.users.frigate = {
      isSystemUser = true;
      group = "frigate";
    };
    users.groups.frigate = {};
    systemd.tmpfiles.rules = [
      "d ${frigateDir} 0750 frigate frigate -"
      "d ${dataDir} 0750 frigate frigate -"
      "d ${configDir} 0750 frigate frigate -"
    ];

    environment.etc."frigate/config.yml".source = frigateConfig.generate "frigate.yml" frigateSettings;

    sops.secrets."frigate/a_user" = {};
    sops.secrets."frigate/a_pass" = {};
    sops.secrets."frigate/z_user" = {};
    sops.secrets."frigate/z_pass" = {};
    sops.secrets."frigate/mqtt_pass" = {};

    sops.templates."frigate.env" = {
      content = ''
        FRIGATE_A_USER=${secret."frigate/a_user"}
        FRIGATE_A_PASS=${secret."frigate/a_pass"}
        FRIGATE_Z_USER=${secret."frigate/z_user"}
        FRIGATE_Z_PASS=${secret."frigate/z_pass"}
        FRIGATE_MQTT_PASS=${secret."frigate/mqtt_pass"}
      '';
      mode = "0400";
    };

    virtualisation.oci-containers.containers.frigate = {
      image = "ghcr.io/blakeblackshear/frigate:stable";

      ports = [
        "${toString cfg.port}:5000"
        "8554:8554"
        "8555:8555/tcp"
        "8555:8555/udp"
      ];

      volumes = [
        "${configDir}:/config"
        "${dataDir}:/media/frigate"
        "/etc/localtime:/etc/localtime:ro"
        "/etc/frigate/config.yml:/config/config.yml:ro"
      ];

      user = "${toString config.users.users.frigate.uid}:${toString config.users.groups.frigate.gid}";

      environmentFiles = [
        config.sops.templates."frigate.env".path
      ];

      extraOptions = [
        "--shm-size=1024m"
      ];
    };

    networking.firewall.allowedTCPPorts = [ cfg.port ];

    myModules.proxy.services.frigate = {
      port = cfg.port;
      proxyWebsockets = true;
    };
  };
}