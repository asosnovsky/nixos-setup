{ config, lib, pkgs, skygUtils, ... }:
let
  cfg = config.skyg.nixos.desktop.tiler.niri;
  makeNiriSystemdService = { description, script, path ? [ ] }: {
    Unit = {
      Description = description;
      After = [ "niri.service" "xdg-desktop-portal.service" ];
      PartOf = [ "niri.service" "tray.target" ];
      BindsTo = [ "niri.service" ];
      Wants = [ "niri.service" "xdg-desktop-portal.service" ];
      WantedBy = [
        "graphical-session.target"
        # "tray.target"
      ];
      Requires = [ "niri.service" ];
    };
    Service = {
      Type = "simple";
      KillMode = "mixed";
      Restart = "on-failure";
      ExecReload = "${pkgs.coreutils}/bin/kill -SIGUSR2 $MAINPID";
      ConditionEnvironment = "WAYLAND_DISPLAY";
    };
  };
in
{
  options = {
    skyg.nixos.desktop.tiler.niri = {
      enable = lib.mkEnableOption
        "niri";
    };
  };
  config = lib.mkIf cfg.enable {
    skyg.nixos.desktop.tiler.enable = true;
    programs.niri = {
      enable = true;
    };
    environment.systemPackages = with pkgs; [
      hypridle
      swayosd
      xwayland-satellite
      adwaita-icon-theme
      papirus-icon-theme
    ];
    system.userActivationScripts.niriConfig.text = skygUtils.makeHyperlinkScriptToConfigs {
      filePath = "niri";
      configSource = "/home/${config.skyg.user.name}/nixos-setup/configs";
    };
    users.users.${config.skyg.user.name}.systemd.user.services.niri-waybar = makeNiriSystemdService {
      description = "Niri's Top Waybar";
      path = [ pkgs.nwg-bar pkgs.niri ];
      script = ''
        ${pkgs.waybar}/bin/waybar \
          --config /home/${config.skyg.user.name}/nixos-setup/configs/niri/waybar/top-bar.jsonc \
          --style /home/${config.skyg.user.name}/nixos-setup/configs/niri/waybar/top-bar.css &
        ${pkgs.waybar}/bin/waybar \
          --config /home/${config.skyg.user.name}/nixos-setup/configs/niri/waybar/bottom-bar.jsonc \
          --style /home/${config.skyg.user.name}/nixos-setup/configs/niri/waybar/bottom-bar.css
      '';
    };
    users.users.${config.skyg.user.name}.systemd.user.services.niri-xwayland = makeNiriSystemdService {
      description = "Niri's xwayland-satellite";
      script = ''
        ${pkgs.xwayland-satellite}/bin/xwayland-satellite
      '';
    };
    users.users.${config.skyg.user.name}.systemd.user.services.niri-hypridle = makeNiriSystemdService {
      description = "Niri's hypridle";
      script = ''
        ${pkgs.hypridle}/bin/hypridle
      '';
    };
    users.users.${config.skyg.user.name}.systemd.user.services.niri-swayosd = makeNiriSystemdService {
      description = "Niri's swayosd";
      script = ''
        ${pkgs.swayosd}/bin/swayosd-server
      '';
    };
  };
}

