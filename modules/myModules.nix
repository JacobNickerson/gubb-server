{ ... }:
{
  imports = [
    ./home-assistant.nix
    ./immich.nix
    ./limine.nix
    ./openssh.nix
    ./restic.nix
    ./samba.nix
    ./wireguard.nix
  ];
}