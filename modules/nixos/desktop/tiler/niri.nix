{ config, lib, pkgs, skygUtils, ... }:
let
  cfg = config.skyg.nixos.desktop.tiler.niri;
  makeNiriSystemdService = { description, script }: {
    inherit description script;
    enable = true;
    requires = [ "niri.service" ];
    reloadIfChanged = true;
    restartIfChanged = true;
    after = [ "niri.service" ];
    partOf = [ "niri.service" ];
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
    ];
    system.userActivationScripts.niriConfig.text = skygUtils.makeHyperlinkScriptToConfigs {
      filePath = "niri";
      configSource = "/home/${config.skyg.user.name}/nixos-setup/configs";
    };
    systemd.user.services.niri-waybar-top = makeNiriSystemdService {
      description = "Niri's Top Waybar";
      script = ''
        ${pkgs.waybar}/bin/waybar \
          --config /home/${config.skyg.user.name}/nixos-setup/configs/niri/waybar/top-config.jsonc \
          --style /home/${config.skyg.user.name}/nixos-setup/configs/niri/waybar/style.css
      '';
    };
    systemd.user.services.niri-waybar-bottom = makeNiriSystemdService {
      description = "Niri's Bottom Waybar";
      script = ''
        ${pkgs.waybar}/bin/waybar \
          --config /home/${config.skyg.user.name}/nixos-setup/configs/niri/waybar/bottom-config.jsonc \
          --style /home/${config.skyg.user.name}/nixos-setup/configs/niri/waybar/style.css
      '';
    };
    systemd.user.services.niri-xwayland-satellite = makeNiriSystemdService {
      description = "Niri's xwayland-satellite";
      script = ''
        ${pkgs.xwayland-satellite}/bin/xwayland-satellite
      '';
    };
  };
}

