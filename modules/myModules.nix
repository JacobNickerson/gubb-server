{ lib, ... }:
{
  imports = [
    ./dnsmasq.nix
    ./duck-dns.nix
    ./frigate.nix
    ./home-assistant.nix
    ./immich.nix
    ./kavita.nix
    ./limine.nix
    ./nginx.nix
    ./mosquitto.nix
    ./openssh.nix
    ./restic.nix
    ./samba.nix
    ./sops-nix.nix
    ./wireguard.nix
  ];
  options.myModules = {
    domain = lib.mkOption {
      type = lib.types.str;
      description = "Top level domain for services";
    };

    server_address = lib.mkOption {
      type = lib.types.str;
      description = "Local address for services";
    };
  };
}