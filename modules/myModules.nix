{ lib, ... }:
{
  imports = [
    ./duck-dns.nix
    ./frigate.nix
    ./gpu.nix
    ./home-assistant.nix
    ./immich.nix
    ./kavita.nix
    ./mosquitto.nix
    ./openssh.nix
    ./proxy.nix
    ./radicale.nix
    ./restic.nix
    ./samba.nix
    ./searxng.nix
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