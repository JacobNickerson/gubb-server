{ config, pkgs, ... }:

{
  imports = [
    ./modules/myModules.nix
  ];

  myModules = {
    home-assistant.enable = true;
    immich.enable = true;
    limine.enable = true;
    openssh.enable = true;
    samba.enable = true;
    wireguard = {
      enable = true;
      ext_interface = "enp3s0f4u2";
      subnet_prefix = "10.100.0";
    };
    restic = {
      enable = true;
      repo = "b2:gubb-server:/";
    };
    sops-nix = {
      enable = true;
      defaultSopsFile = ./secrets;
    };
  };

  nix.settings.experimental-features = [ "nix-command" "flakes" ];

  networking = {
    wireless.enable = false;
    wireless.iwd.enable = true;
    networkmanager.enable = true;
    networkmanager.wifi.backend = "iwd";
    firewall.enable = true;
  };

  time.timeZone = "America/New_York";

  i18n.defaultLocale = "en_US.UTF-8";
  i18n.extraLocaleSettings = {
    LC_ADDRESS = "en_US.UTF-8";
    LC_IDENTIFICATION = "en_US.UTF-8";
    LC_MEASUREMENT = "en_US.UTF-8";
    LC_MONETARY = "en_US.UTF-8";
    LC_NAME = "en_US.UTF-8";
    LC_NUMERIC = "en_US.UTF-8";
    LC_PAPER = "en_US.UTF-8";
    LC_TELEPHONE = "en_US.UTF-8";
    LC_TIME = "en_US.UTF-8";
  };

  services.xserver.xkb = {
    layout = "us";
    variant = "";
  };

  environment.systemPackages = with pkgs; [
    vim
    git
    zip
    unzip
    btop
    yazi
    python3
    rar
  ];

  environment.sessionVariables = {

  };
  environment.variables = {
    EDITOR = "vim";
    VISUAL = "vim";
  };
  environment.pathsToLink = [ "/share/zsh" ];

  systemd.tmpfiles.rules = [
    "d /srv 755 root root -"
    "d /srv/postgresql 750 postgres postgres -"
    "d /swap 755 root root -"
  ];
  
  services.postgresql.dataDir = "/srv/postgresql";

  # Allowing lid to close
  services.logind.settings.Login = {
    HandleLidSwitch = "ignore";
    HandleLidSwitchDocked = "ignore";
    HandleLidSwitchExternalPower = "ignore";
  };

  # Patch to allow VSCode remote server
  services.vscode-server.enable = true;

  # This value determines the NixOS release from which the default
  # settings for stateful data, like file locations and database versions
  # on your system were taken. It‘s perfectly fine and recommended to leave
  # this value at the release version of the first install of this system.
  # Before changing this value read the documentation for this option
  # (e.g. man configuration.nix or on https://nixos.org/nixos/options.html).
  system.stateVersion = "25.11"; # Did you read the comment?
}
