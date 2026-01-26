{ config
, lib
, pkgs
, unstablePkgs
, ...
}:
let
  cfg = config.skyg.nixos.desktop.tiler;
in
{
  imports = [
    ./hyprland.nix
    ./niri.nix
    ./swww.nix
  ];
  options = {
    skyg.nixos.desktop.tiler = {
      enable = lib.mkEnableOption "Enable libraries for tiling window managers";
    };
  };
  config = lib.mkIf cfg.enable {
    users.users.${config.skyg.user.name} = {
      extraGroups = [
        "input"
      ];
    };
    # services.blueman.enable = true;
    programs.dank-material-shell = {
      enable = true;
      dgop.package = unstablePkgs.dgop;
      systemd = {
        enable = true; # Systemd service for auto-start
        restartIfChanged = true; # Auto-restart dms.service when dankMaterialShell changes
      };
    };
    # programs.hyprlock.enable = true;
    # programs.nm-applet.enable = true;
    environment.systemPackages = with pkgs; [
      # Protocols and libraries
      xwayland-satellite
      libnotify
      # Notifications
      mako
      wofi
      rofi
      # Control Tools
      pavucontrol
      playerctl
      brightnessctl
      # networkmanagerapplet
      blueman
      # Apps
      walker
      # waybar
      # nwg-bar
      gnome-calendar
      nautilus
      # Screen capture and recording tools
      grim
      slurp
      satty
      wf-recorder
    ];
  };
}
