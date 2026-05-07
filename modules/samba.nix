{ config, ... }:
{
  users.groups.smb = {};
  services.samba = {
    enable = true;
    openFirewall = true;
    settings = {
      global = {
        "workgroup" = "Gubbs";
        "server string" = "Gubb NAS";
        "netbios name" = "gubbserver";
        "security" = "user";
        "hosts allow" = "192.168.";
        "hosts deny" = "0.0.0.0/0";
        "guest account" = "nobody";
        "map to guest" = "bad user";
        "min protocol" = "SMB2";
      };
      "gubb-storage" = {
        "path" = "/storage/gubb";
        "browseable" = "yes";
        "read only" = "no";
        "guest ok" = "no";
        "create mask" = "0640";
        "directory mask" = "0750";
        "valid users" = "@smb";
      };
    };
  };

  services.samba-wsdd = {
    enable = true;
    openFirewall = true;
  };

  networking.firewall.enable = true;
  networking.firewall.allowPing = true;
}
