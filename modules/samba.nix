{ config, lib, ... }:
let
  cfg = config.myModules.samba;
  smb_dir = "/srv/nas";
in
{
  options.myModules.samba = {
    enable = lib.mkEnableOption "Samba server";
  };

  config = lib.mkIf cfg.enable {
    users.groups.smb = {};
    systemd.tmpfiles.rules = [
      "d ${smb_dir} 0770 root smb -"
    ];
    services.samba = {
      enable = true;
      openFirewall = true;
      settings = {
        global = {
          "workgroup" = "Gubbs";
          "server string" = "Gubb NAS";
          "netbios name" = "gubbserver";
          "security" = "user";
          "hosts allow" = "192.168. 10.100.0.";
          "hosts deny" = "0.0.0.0/0";
          "guest account" = "nobody";
          "map to guest" = "bad user";
          "min protocol" = "SMB2";
        };
        "gubb-storage" = {
          "path" = "${smb_dir}";
          "browseable" = "yes";
          "read only" = "no";
          "guest ok" = "no";
          "create mask" = "0644";
          "directory mask" = "0755";
          "valid users" = "@smb";
        };
      };
    };

    services.samba-wsdd = {
      enable = true;
      openFirewall = true;
    };
  };
}