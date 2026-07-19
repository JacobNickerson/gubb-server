{ config, lib, ... }:
let
  cfg = config.myModules.my-module;
in
{
  options.myModules.my-module = {
    enable = lib.mkEnableOption "A template for a new module";
  };

  config = lib.mkIf cfg.enable {

  };
}