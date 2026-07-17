{ ... }:
{
  imports = [
    ./duck-dns.nix
    ./frigate.nix
    ./home-assistant.nix
    ./immich.nix
    ./kavita.nix
    ./limine.nix
    ./mosquitto.nix
    ./openssh.nix
    ./restic.nix
    ./samba.nix
    ./sops-nix.nix
    ./wireguard.nix
  ];
}