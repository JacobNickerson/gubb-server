{ config, pkgs, lib, ... }:
let
  cfg = config.myModules.wireguard;
  key_dir = "/etc/systemd/network/keys";
in
{
  options.myModules.wireguard = {
    enable = lib.mkEnableOption "WireGuard server";

    external_address = lib.mkOption {
      type = lib.types.str;
      description = "External network address to route VPN DNS entry to";
    };

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
    systemd.tmpfiles.rules = [
      "d ${key_dir} 0750 root systemd-network -"
    ];
    sops.secrets."wireguard/key" = {
      owner = "root";
      group = "systemd-network";
      mode = "0640";
    };

    networking.useNetworkd = true;
    networking.wireguard.enable = true;

    systemd.network.networks."50-${cfg.int_interface}" = {
      matchConfig.Name = cfg.int_interface;

      address = [ "${cfg.subnet_prefix}.1/24" ];
    };

    systemd.network.netdevs."50-${cfg.int_interface}" = {
      netdevConfig = {
        Name = cfg.int_interface;
        Kind = "wireguard";
        MTUBytes = "1420";
      };

      wireguardConfig = {
        PrivateKeyFile = config.sops.secrets."wireguard/key".path;
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
        { # BunTop
          PublicKey = "+ENI1SFf02yH04jWmIwnVcMVYywkOkTbvggKa0MrkQE=";
          AllowedIPs = [ "${cfg.subnet_prefix}.6/32" ];
        }
      ];
    };

    boot.kernel.sysctl = {
      "net.ipv4.ip_forward" = 1;
      "net.ipv6.conf.all.forwarding" = 1;
    };

    networking.nat = {
      enable = true;
      externalInterface = cfg.ext_interface;
      internalInterfaces = [ cfg.int_interface ];
    };

    networking.firewall.allowedUDPPorts = [ cfg.port ];

    # NOTE: WireGuard does not use the usual proxy config because it doesn't use HTTP/S
    #       Additionally it routes to external IP because it broke the clients if it routes to local
    services.dnsmasq.settings.address = lib.mkIf config.myModules.proxy.enable (lib.mkAfter [
      "/vpn.${config.myModules.domain}/${cfg.external_address}"
    ]);

    environment.systemPackages = with pkgs; [
      wireguard-tools
    ];
  };
}
