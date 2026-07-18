{ config, lib, ... }:
let
  cfg = config.myModules.openssh;
in
{
  options.myModules.openssh = {
    enable = lib.mkEnableOption "OpenSSH host";

    port = lib.mkOption {
      type = lib.types.int;
      default = 42067;
      description = "Port used by sshd";
    };
  };

  config = lib.mkIf cfg.enable {
    services.openssh = {
      enable = true;
      ports = [ cfg.port ];
      settings = {
        PasswordAuthentication = false;
        KbdInteractiveAuthentication = false;
        PermitRootLogin = "no";
        AllowUsers = null;
        UseDns = true;
        X11Forwarding = false;
      };
    };

    services.endlessh = {
      enable = true;
      port = 22;
      openFirewall = true;
    };

    services.fail2ban = {
      enable = true;
    };

    users.users."jacobnickerson".openssh.authorizedKeys.keys = [
      "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIOGsgM2ftNlPvn8Vltsj3+WuHhVZHMIW+5Iqk2ajfXJi jacobnickerson@PortaJake"
      "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIMPHmgqYS9H+fV4QMzM35tbYrGKwQuYAKBBldw32dZBb jacobnickerson@NixJake"
      "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIPzsH/3uV5BtilKYe9t8Ej7J9BNnHn3ltcdFHOWhJbEr UltraPortaJake"
    ];
  };
}