{ hostName, firewall }:
{ pkgs, ... }:
{
  # Bootloader.
  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;

  networking.hostName = hostName; # Define your hostname.

  # Enable networking
  networking.networkmanager.enable = true;
  networking.firewall = firewall;

  # Set your time zone.
  time.timeZone = "America/Toronto";

  # Select internationalisation properties.
  i18n.defaultLocale = "en_CA.UTF-8";

  # System Packages
  programs.zsh.enable = true;
  environment.systemPackages = with pkgs; [
    zsh
    git
    vscode
    nil	  
    docker-compose 
    usbutils
    wget
    ollama
    appimage-run
    htop
    nfs-utils
    (import (fetchTarball "https://install.devenv.sh/latest")).default
  ];
  services.nfs.server.enable = true;
  # Default Session Variables
  environment.sessionVariables = rec {
#    PROMPT = "%(!.%{%F{yellow}%}.)\$USER@%{\$fg[white]%}%M \${ret_status} %{\$fg[cyan]%}%c%{\$reset_color%} $(git_prompt_info)";
  };
  # Exclude Gnome packages
  environment.gnome.excludePackages = [ 
    pkgs.gnome-tour 
  ];
  services.xserver.excludePackages = [ 
    pkgs.xterm 
  ]; 

  # Fonts
  fonts = {
    packages = with pkgs; [ 
      (nerdfonts.override { fonts = [ "FiraCode" "DroidSansMono" ]; })
    ];

    fontconfig = {
      enable = true;
      defaultFonts = {
        serif = [ "FiraCode" "DroidSansMono" ];
        sansSerif = [ "FiraCode" "DroidSansMono" ];
        monospace = [ "FiraCode" ];
      };
    };
  };
}
