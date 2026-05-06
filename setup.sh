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
btrfs subvolume create /mnt/@storage
umount /mnt
mkdir -p /swap /storage
mount $1 /swap -o subvol=@swap
mount $1 /storage -o subvol=@storage
nixos-generate-config --show-hardware-config > hardware-configuration.nix
nixos-rebuild boot --flake .#GubbServer
