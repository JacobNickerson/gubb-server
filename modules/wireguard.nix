{ config, pkgs, lib, ... }:
let
  cfg = config.myModules.wireguard;
  key_dir = "/etc/systemd/network/keys";
  key_file = "${key_dir}/${cfg.int_interface}.key";
in
{
  options.myModules.wireguard = {
    enable = lib.mkEnableOption "WireGuard server";

    port = lib.mkOption {
      type = lib.types.int;
      default = 42167;
      description = "UDP port used by the WireGuard server";
    };

    ext_interface = lib.mkOption {
      type = lib.types.str;
      default = "eth0";
      description = "External network interface used for NAT";
    };

    subnet_prefix = lib.mkOption {
      type = lib.types.str;
      default = "10.0.0";
      description = "First three octets of the WireGuard IPv4 subnet";
    };

    int_interface = lib.mkOption {
      type = lib.types.str;
      default = "wg0";
      description = "Internal WireGuard network interface";
    };
  };

  config = lib.mkIf cfg.enable {
    networking.useNetworkd = true;
    networking.wireguard.enable = true;

    boot.kernel.sysctl = {
      "net.ipv4.ip_forward" = 1;
      "net.ipv6.conf.all.forwarding" = 1;
    };

    networking.firewall = {
      enable = true;
      allowedUDPPorts = [ cfg.port ];
    };

    networking.nat = {
      enable = true;
      externalInterface = cfg.ext_interface;
      internalInterfaces = [ cfg.int_interface ];
    };

    systemd.network.networks."50-${cfg.int_interface}" = {
      matchConfig.Name = cfg.int_interface;

      address = [ "${cfg.subnet_prefix}.1/24" ];

      networkConfig = {
        #DNS = "${cfg.subnet_prefix}.1"; TODO: enable if setting up DNS resolver
      };
    };

    systemd.tmpfiles.rules = [
      "d ${key_dir} 0750 root systemd-network -"
    ];
    system.activationScripts.wireguard-key = ''
      if [ ! -f ${key_file} ]; then
        ${pkgs.wireguard-tools}/bin/wg genkey > ${key_file}
        chown root:systemd-network ${key_file}
        chmod 640 ${key_file}
      fi
    '';

    systemd.network.netdevs."50-${cfg.int_interface}" = {
      netdevConfig = {
        Name = cfg.int_interface;
        Kind = "wireguard";
        MTUBytes = "1420";
      };

      wireguardConfig = {
        PrivateKeyFile = key_file;
        ListenPort = cfg.port;
      };

      wireguardPeers = [
        { # PortaJake
          PublicKey = "q0PVIe44Zhduc7SHLpWvxrGROEvEZmawMVj7fAfrIxM=";
          AllowedIPs = [ "${cfg.subnet_prefix}.2/32" ];
          PersistentKeepalive = 25;
        }
        { # PhoneJake
          PublicKey = "e+sZpu+5OfFn5Lxqsb/sytqv1auf07HgxzUS0oT4Cmg=";
          AllowedIPs = [ "${cfg.subnet_prefix}.3/32" ];
        }
        { # BunPhone
          PublicKey = "h4WOuljd3KTSWDJ6bWISmJhi46FWAqO+LvD4sPgUkHc=";
          AllowedIPs = [ "${cfg.subnet_prefix}.5/32" ];
        }
      ];
    };

    # TODO: enable this if setting up some type of dns resolver
    # services.resolved.enable = true;
    environment.systemPackages = with pkgs; [
      wireguard-tools
    ];
  };
}
