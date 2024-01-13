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
  environment.systemPackages = with pkgs; [
    git
    vscode
    nil	  
    docker-compose 
    usbutils
    wget
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