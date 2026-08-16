{ config, lib, pkgs, ... }:
let
  cfg = config.myModules.gpu;
in
{
  options.myModules.gpu = {
    nvidia.enable = lib.mkEnableOption "Enable Nvidia GPU drivers";
    amdgpu.enable = lib.mkEnableOption "Enable AMD GPU drivers";
  };
  config = lib.mkMerge [
    (lib.mkIf (cfg.nvidia.enable || cfg.amdgpu.enable) {
      hardware.graphics = {
        enable = true;
        enable32Bit = true;
      };
    })
    
    (lib.mkIf cfg.nvidia.enable {
      services.xserver.videoDrivers = lib.mkAfter [ "nvidia" ];
      hardware.nvidia = {
        modesetting.enable = true;
        powerManagement.enable = true;
        open = true;
        nvidiaSettings = true;
      };
      boot.kernelParams = [
        "nvidia.NVreg_PreserveVideoMemoryAllocations=1"  # May cause instability, remove if so
      ]; 
    })

    (lib.mkIf cfg.amdgpu.enable {
      hardware.graphics.extraPackages = with pkgs; [
        rocmPackages.clr.icd
      ];
      services.xserver.videoDrivers = lib.mkAfter [ "amdgpu" ];
      boot.initrd.kernelModules = [ "amdgpu" ];
      boot.kernelParams = [

      ];  
      services.lact.enable = true;
    })
  ];
}