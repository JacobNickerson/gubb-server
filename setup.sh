#!/usr/bin/env bash

if [ -z $1 ]; then
  echo "usage: ./setup.sh <root-partition-path>"
  exit 1
fi
if [ "$EUID" -ne 0 ]; then
  echo "error: must be run as sudo"
  exit 1
fi
if [ ! -d /storage ]; then
  echo "error: storage partition must be mounted at /storage"
  exit 1
fi

echo "Generating secure boot keys..."
nix-shell -p sbctl --command "sbctl create-keys"
if [ ! -d /var/lib/sbctl/keys ]; then
  echo "error: failed to generate secure boot keys"
  exit 1
fi

echo "Creating swap subvolume..."
mkdir -p /mnt
mount $1 /mnt
btrfs subvolume create /mnt/@swap
umount /mnt
mkdir -p /swap
mount $1 /swap -o subvol=@swap

echo "Building system..."
nixos-generate-config --show-hardware-config > hardware-configuration.nix
nixos-rebuild boot --flake .#GubbServer