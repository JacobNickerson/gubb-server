{ lib, ... }:
{
  imports = [
    ./duck-dns.nix
    ./frigate.nix
    ./gpu.nix
    ./home-assistant.nix
    ./homepage-dashboard.nix
    ./immich.nix
    ./kavita.nix
    ./limine.nix
    ./llama-cpp.nix
    ./minecraft.nix
    ./mosquitto.nix
    ./opencloud.nix
    ./openssh.nix
    ./open-webui.nix
    ./proxy.nix
    ./radicale.nix
    ./restic.nix
    ./samba.nix
    ./searxng.nix
    ./shui.nix
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