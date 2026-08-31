{ config
, lib
, pkgs
, ...
}:
let
  cfg = config.skyg.nixos.desktop.tiler;
in
{
  imports = [
    ./hyprland.nix
    ./niri.nix
    ./niri-touchscreen-gestures.nix
    ./noctalia.nix
    ./quickshell.nix
    ./swww.nix
  ];
  options = {
    skyg.nixos.desktop.tiler = {
      enable = lib.mkEnableOption "Enable libraries for tiling window managers";
    };
  };
  config = lib.mkIf cfg.enable {
    environment.sessionVariables.ELECTRON_OZONE_PLATFORM_HINT = "wayland";
    users.users.${config.skyg.user.name} = {
      extraGroups = [
        "input"
      ];
    };

    # =========================
    # Keyring / Secrets Service
    # =========================
    services.gnome.gnome-keyring.enable = true;
    services.gnome.gcr-ssh-agent.enable = false; # use standard SSH agent instead
    security.pam.services.greetd = {
      enableGnomeKeyring = true;
      text = lib.mkDefault ''
        auth      include  login
        account   include  login
        password  include  login
        session   include  login
      '';
    };
    security.pam.services.login.enableGnomeKeyring = true;
    security.polkit.enable = true;
    programs.ssh.startAgent = true;

    environment.systemPackages = with pkgs; [
      # Protocols and libraries
      xwayland-satellite
      libnotify
      kdePackages.qtwebsockets

      # Keyring / secrets
      libsecret
      gcr
      seahorse

      # Control Tools
      pavucontrol
      playerctl
      brightnessctl
      blueman
      # Apps
      gnome-calendar
      nautilus
      # Screen capture and recording tools
      satty # image annotation
      slurp
      wf-recorder # video capture
      # Video Wallpaper
      mpv
      mpvpaper
    ];
  };
}
