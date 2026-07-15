{ config, lib, ... }:
let
  cfg = config.myModules.mosquitto;
in
{
  options.myModules.mosquitto = {
    enable = lib.mkEnableOption "MQTT broker";
  };

  config = lib.mkIf cfg.enable {
    sops.secrets."frigate/mqtt_pass" = {
      restartUnits = [ "mosquitto.service" ];
    };

    services.mosquitto = {
      enable = true;

      listeners = [
        {
          port = 1883;
          users.frigate = {
            passwordFile = config.sops.secrets."frigate/mqtt_pass".path;
            acl = [ "readwrite #" ];
          };
        }
      ];
    };
  };
}
