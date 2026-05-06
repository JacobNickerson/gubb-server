{ config, lib, pkgs, modulesPath, ... }:
{
  imports = [ 
      ./hardware-configuration.nix
  ];

  fileSystems."/".options = [ "compress=zstd:1" "noatime" ];
  fileSystems."/storage".options = [ "compress=zstd:3" "noatime" ];
  fileSystems."/swap".options = [ "compress=no" "nodatacow" "noatime" ];
  swapDevices = lib.mkForce [
     {
       device = "/swap/swapfile";
       size = 16 * 1024;
     }
  ];
}
