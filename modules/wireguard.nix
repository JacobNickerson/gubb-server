{ port ? 42167, ext_interface ? "eth0", subnet_prefix ? "10.0.0", int_interface ? "wg0" }:
{ config, pkgs, ... }:
let
  key_dir = "/etc/systemd/network/keys";
  key_file = "${key_dir}/${int_interface}.key";
in
{
  networking.useNetworkd = true;
  networking.wireguard.enable = true;

  boot.kernel.sysctl = {
    "net.ipv4.ip_forward" = 1;
    #"net.ipv6.conf.all.forwarding" = 1;  # TODO: Look into setting up ipv6
  };

  networking.firewall = {
    enable = true;
    allowedUDPPorts = [ port ];
  };

  networking.nat = {
    enable = true;
    externalInterface = ext_interface;
    internalInterfaces = [ int_interface ];
  };

  systemd.network.networks."50-${int_interface}" = {
    matchConfig.Name = int_interface;

    address = [
      "${subnet_prefix}.1/24"
    ];

    networkConfig = {
      DNS = "${subnet_prefix}.1";
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

  systemd.network.netdevs."50-${int_interface}" = {
    netdevConfig = {
      Name = int_interface;
      Kind = "wireguard";
      MTUBytes = "1420";
    };

    wireguardConfig = {
      PrivateKeyFile = key_file;
      ListenPort = port;
    };

    wireguardPeers = [
      { # PortaJake
        PublicKey = "PORTA_JAKE_KEY";
        AllowedIPs = [ "${subnet_prefix}.2/32" ];
        PersistentKeepalive = 25;
      }
    ];
  };

  # TODO: enable this if setting up some type of dns resolver
  # services.resolved.enable = true;
  environment.systemPackages = with pkgs; [
    wireguard-tools
  ];
}
