#!/usr/bin/env bash

if [ -z $1 ]; then
  echo "usage: ./setup.sh <root-partition-path>"
  exit 1
fi
if [ "$EUID" -ne 0 ]; then
  echo "error: must be run as sudo"
  exit 1
fi

mkdir -p /mnt

mount $1 /mnt
btrfs subvolume create /mnt/@swap
umount /mnt
mkdir -p /swap
mount $1 /swap -o subvol=@swap

# New group is defined in nix config, but must be added here since this script is run before nix config
groupadd smb
mkdir -p /storage/gubb
chown -R root:smb /storage/gubb
chmod 770 /storage/gubb

nixos-generate-config --show-hardware-config > hardware-configuration.nix
nixos-rebuild boot --flake .#GubbServer
