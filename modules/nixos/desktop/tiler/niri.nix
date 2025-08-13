{ config, lib, pkgs, skygUtils, ... }:
let
  cfg = config.skyg.nixos.desktop.tiler.niri;
  makeNiriSystemdService = { description, script, path ? [ ] }: {
    inherit description script path;
    enable = true;
    requires = [ "niri.service" ];
    reloadIfChanged = true;
    restartIfChanged = true;
    after = [ "niri.service" ];
    partOf = [ "niri.service" ];
    bindsTo = [ "niri.service" ];
    wants = [ "niri.service" ];
    wantedBy = [ "graphical-session.target" ];
    serviceConfig = {
      Type = "simple";
      Restart = "on-failure";
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
    ];
    system.userActivationScripts.niriConfig.text = skygUtils.makeHyperlinkScriptToConfigs {
      filePath = "niri";
      configSource = "/home/${config.skyg.user.name}/nixos-setup/configs";
    };
    systemd.user.services.niri-waybar = makeNiriSystemdService {
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
    systemd.user.services.niri-xwayland = makeNiriSystemdService {
      description = "Niri's xwayland-satellite";
      script = ''
        ${pkgs.xwayland-satellite}/bin/xwayland-satellite
      '';
    };
    systemd.user.services.niri-hypridle = makeNiriSystemdService {
      description = "Niri's hypridle";
      script = ''
        ${pkgs.hypridle}/bin/hypridle
      '';
    };
    systemd.user.services.niri-swayosd = makeNiriSystemdService {
      description = "Niri's swayosd";
      script = ''
        ${pkgs.swayosd}/bin/swayosd-server
      '';
    };
  };
}

