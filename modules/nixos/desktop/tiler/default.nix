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
      apps = {
        control = {
          enable = lib.mkEnableOption "control apps (pavucontrol, playerctl, brightnessctl, blueman)";
        };
        gnome = {
          enable = lib.mkEnableOption "GNOME apps (nautilus, gnome-calendar, seahorse, gcr)";
        };
        media = {
          enable = lib.mkEnableOption "media/capture apps (wf-recorder, mpv, mpvpaper)";
        };
      };
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

    # Always-on tiler plumbing: Wayland protocols, notification lib, secrets lib.
    environment.systemPackages = with pkgs;
      [
        # Protocols and libraries
        xwayland-satellite
        libnotify
        kdePackages.qtwebsockets

        # Keyring / secrets library
        libsecret
      ]
      # App groups are opt-in so slim hosts (e.g. hl-pi1) don't pull them in.
      ++ (lib.optionals cfg.apps.control.enable [
        # Control Tools
        pavucontrol
        playerctl
        brightnessctl
        blueman
      ])
      ++ (lib.optionals cfg.apps.gnome.enable [
        # GNOME apps
        gnome-calendar
        nautilus
        seahorse
        gcr
      ])
      ++ (lib.optionals cfg.apps.media.enable [
        # Screen capture / video wallpaper
        wf-recorder
        mpv
        mpvpaper
      ]);
  };
}
