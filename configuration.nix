{ config, pkgs, ... }:

{
  imports = [
    ./modules/myModules.nix
  ];

  myModules = {
    domain = "knitnet.org";
    server_address = "192.168.5.88";

    duck-dns = {
      enable = true;
      domain = "shui-nails";
    };
    gpu.nvidia.enable = true;
    gpu.nvidia.powerLimit = 240;
    home-assistant.enable = true;
    immich = {
      enable = true;
      port = 42267;
    };
    kavita = {
      enable = true;
      port = 42467;
      create-library = "/srv/nas/kavita";
      allow-nas = true;
    };
    limine = {
      enable = true;
      enableSecureBoot = true;
    };
    llama-cpp = {
      enable = true;
      port = 42567;
      model_dir = "/srv/llama/models";
    };
    minecraft = {
      enable = true;
      initMem = "1G";
      maxMem = "12G";
    };
    openssh.enable = true;
    open-webui = {
      enable = true;
      port = 42667;
    };
    proxy = {
      enable = true;
    };
    samba.enable = true;
    wireguard = {
      enable = true;
      external_address = "47.199.149.116";
      ext_interface = "enp6s0";
      subnet_prefix = "10.100.0";
    };
    radicale = {
      enable = true;
      port = 5232;
    };
    restic = {
      enable = true;
      repo = "b2:gubb-server:/";
      paths = [ "/srv" ];
      exclude = [ "/srv/llama" ];
    };
    searxng = {
      enable = true;
      port = 42767;
    };
    shui = {
      enable = true;
      port = 42867;
      dataDir = "/srv/shui";
      allowedHosts = "shui.knitnet.org";
    };
    sops-nix = {
      enable = true;
      defaultSopsFile = ./secrets;
    };
    frigate.enable = true;
    mosquitto.enable = true;
  };
  programs = {
    fish.enable = true;
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
