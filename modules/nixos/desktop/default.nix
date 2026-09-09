{ config
, lib
, pkgs
, ...
}:
let
  cfg = config.skyg.nixos;
  skygUser = config.skyg.user;
  coreSettings = {
    environment.sessionVariables.NIXOS_OZONE_WL = "1";
    users.users.${skygUser.name}.extraGroups = [
      "input"
      "disk"
      "wheel"
      "tty"
      "dialout"
      "plugdev"
      "uucp"
    ];
    services.dbus.enable = true;
    services.displayManager.enable = true;
  };
  nonSlimSettings = {
    programs.xwayland.enable = true;
    services.xserver = {
      enable = true;
      xkb.layout = "us";
      xkb.variant = "";
    };
    services.libinput.enable = true;
    environment.systemPackages = with pkgs; [
      # Browser
      (chromium.override { enableWideVine = true; })
      # General utils
      libinput
      busybox
      gcc
      eog # image viewer
      # copy to clipboard
      wl-clipboard-x11
      xclip
      # video
      vlc
      # terminal
      ghostty
      # useful
      wayland-utils
      wofi-emoji
      wl-clipboard
    ];
    programs.chromium = {
      enable = true;
      enablePlasmaBrowserIntegration = true;
      extensions = [
        "nngceckbapebfimnlniiiahkandclblb" # bitwarden
        "gcbommkclmclpchllfjekcdonpmejbdp" # https everywhere
        "cjpalhdlnbpafiamejdnhcphjbkeiagm" # ublock origin
      ];
    };
    services.avahi = {
      enable = true;
      nssmdns4 = true;
    };
    services.upower.enable = true;
    services.pipewire = {
      enable = true;
      audio.enable = true;
      pulse.enable = true;
      jack.enable = true;
    };
    xdg = {
      autostart.enable = true;
      mime.enable = true;
      menus.enable = true;
      icons.enable = true;
      sounds.enable = true;
      terminal-exec.enable = true;
      portal = {
        enable = true;
        extraPortals = [
          pkgs.xdg-desktop-portal
        ];
      };
    };
  };
in
{
  imports = [
    ./cosmic.nix
    ./kde.nix
    ./crypto.nix
    ./gnome.nix
    ./tiler
    ./stylix
    ./printers.nix
    ./fixes
  ];

  options = {
    skyg.nixos.desktop = {
      enable = lib.mkEnableOption "Enable Desktop";
      slimMode = lib.mkEnableOption "Enable slim mode: skip Xorg, browsers, and heavy desktop apps.";
    };
  };
  config = lib.mkMerge [
    (lib.mkIf cfg.desktop.enable coreSettings)
    (lib.mkIf (cfg.desktop.enable && !cfg.desktop.slimMode) nonSlimSettings)
  ];
}
