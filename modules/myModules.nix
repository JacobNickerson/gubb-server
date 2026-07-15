{ ... }:
{
  imports = [
    ./frigate.nix
    ./home-assistant.nix
    ./immich.nix
    ./limine.nix
    ./mosquitto.nix
    ./openssh.nix
    ./restic.nix
    ./samba.nix
    ./sops-nix.nix
    ./wireguard.nix
  ];
}