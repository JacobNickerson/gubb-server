{ config, lib, pkgs, ... }:
let
  cfg = config.myModules.llama-cpp;
  llama-pkg = (pkgs.llama-cpp.override {
    cudaSupport = config.myModules.gpu.nvidia.enable;
    # rocmSupport = config.myModules.gpu.amdgpu.enable;
    rocmSupport = false;  # NOTE: As of 08/24/2026, Vulkan outperforms ROCm for token gen on a 7900XTX
    vulkanSupport = true;
  });
in
{
  options.myModules.llama-cpp = {
    enable = lib.mkEnableOption "llama.cpp local LLM inference server";
    port = lib.mkOption {
      type = lib.types.port;
      default = 8080; 
      example = 8080; 
    };
    model_dir = lib.mkOption {
      type = lib.types.path;
      example = "/var/lib/llama/models";
    };
  };

  config = lib.mkIf cfg.enable {
    assertions = [
      {
        assertion = (!(builtins.pathExists cfg.model_dir)) || ((builtins.readFileType cfg.model_dir) == "directory");
        message = "Configured model directory already exists and is not a directory";
      }
    ];

    systemd.tmpfiles.rules = [
      "d ${cfg.model_dir} 0777 root root -"
    ];

    services.llama-cpp = {
      enable = true;
      settings = {
        host = "127.0.0.1";
        port = cfg.port;
        models-dir = cfg.model_dir;
        sleep-idle-seconds = 300;
      };
      openFirewall = true;
      package = llama-pkg;
    };

    environment.systemPackages = [
      llama-pkg
    ];

    myModules.proxy.services.llama = {
      port = cfg.port;
      dns.enable = true;
      nginx = {
        enable = true;
        enableACME = true;
      };
    };
  };
}