{ config, pkgs, lib, ... }:
let
  cfg = config.myModules.limine;
in
{
  options.myModules.limine = {
    enable = lib.mkEnableOption "Limine bootloader with secure boot";
  };

  config = lib.mkIf cfg.enable {
    boot.loader = lib.mkForce {
      systemd-boot.enable = false;
      limine.enable = true;
      limine.secureBoot.enable = true;
      efi.canTouchEfiVariables = true;
    };
    boot.kernelPackages = pkgs.linuxPackages_latest;

    environment.systemPackages = with pkgs; [
      sbctl
    ];
  };
}
