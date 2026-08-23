{ config, lib, pkgs, ... }:
let
  cfg = config.myModules.gpu;
  nv_command = "${config.hardware.nvidia.package.bin}/bin/nvidia-smi";
in
{
  options.myModules.gpu = {
    nvidia = lib.mkOption {
      type = lib.types.submodule {
        options = {
          enable = lib.mkEnableOption "Enable Nvidia GPU drivers";
          powerLimit = lib.mkOption {
            type = lib.types.nullOr lib.types.int;
            description = "Set Nvidia GPU power limit in watts (50-450W)";
            default = null;
          };
        };
      };
      default = {};
      description = "Nvidia GPU settings";
    };
    amdgpu = lib.mkOption {
      type = lib.types.submodule {
        options = {
          enable = lib.mkEnableOption "Enable AMD GPU drivers";
        };
      };
      default = {};
      description = "AMD GPU settings";
    };
    intel = lib.mkOption {
      type = lib.types.submodule {
        options = {
          enable = lib.mkEnableOption "Enable Intel GPU drivers";
        };
      };
      default = {};
      description = "Intel GPU settings";
    };
  };

  config = lib.mkMerge [
    (lib.mkIf (builtins.any (gpu: gpu.enable) (builtins.attrValues cfg)) {
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
        nvidiaPersistenced = true;
      };
      boot.kernelParams = [
        "nvidia.NVreg_PreserveVideoMemoryAllocations=1"  # May cause instability, remove if so
      ]; 
    })

    (lib.mkIf (cfg.nvidia.enable && cfg.nvidia.powerLimit != null) {
      assertions = lib.mkAfter [
        {
          assertion = (cfg.nvidia.powerLimit >= 50 && cfg.nvidia.powerLimit <= 450);
          message = "Power limit must be between 50 and 450 watts";
        }
      ];
      systemd.services."nvidia-power-limit" = {
        description = "Set Nvidia GPU power limit";
        after = [ "nvidia-persistenced.service" ];
        wants = [ "nvidia-persistenced.service" ];
        script = ''
          if ! ${nv_command} -pl ${toString cfg.nvidia.powerLimit}; then
            echo "ERROR: Failed to set power limit to ${toString cfg.nvidia.powerLimit}W" >&2
            exit 1
          fi
        '';
        serviceConfig = {
          Type = "oneshot";
        };
      };
      system.activationScripts.nvidia-power-limit = ''
        ${pkgs.systemd}/bin/systemctl restart nvidia-power-limit.service
      '';
    })

    (lib.mkIf cfg.amdgpu.enable {
      hardware.graphics.extraPackages = with pkgs; [
        rocmPackages.clr.icd
      ];
      services.xserver.videoDrivers = lib.mkAfter [ "amdgpu" ];
      boot.initrd.kernelModules = [ "amdgpu" ];
      boot.kernelParams = [
        "amdgpu.ppfeaturemask=0xffffffff"
      ];  
      services.lact.enable = true;
    })

    (lib.mkIf cfg.intel.enable {
      hardware.graphics.extraPackages = with pkgs; [
        intel-media-driver
        vpl-gpu-rt
      ];
      environment.sessionVariables = {
        LIBVA_DRIVER_NAME = "iHD";
      };
    })
  ];
}