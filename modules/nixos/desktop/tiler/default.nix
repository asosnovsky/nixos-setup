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
    environment.sessionVariables.ELECTRON_OZONE_PLATFORM_HINT = "wayland";
    users.users.${config.skyg.user.name} = {
      extraGroups = [
        "input"
      ];
    };
    programs.dank-material-shell = {
      enable = true;
      dgop.package = unstablePkgs.dgop;
      systemd = {
        enable = true; # Systemd service for auto-start
        restartIfChanged = true; # Auto-restart dms.service when dankMaterialShell changes
      };
    };

    # =========================
    # Keyring / Secrets Service
    # =========================
    services.gnome.gnome-keyring.enable = true;
    security.pam.services.greetd.enableGnomeKeyring = true;
    security.pam.services.login.enableGnomeKeyring = true;
    security.polkit.enable = true;
    programs.ssh.startAgent = false; # gnome-keyring provides ssh-agent

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
    ];
  };
}
