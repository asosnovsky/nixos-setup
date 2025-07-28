{ config, lib, pkgs, skygUtils, ... }:
let
  cfg = config.skyg.nixos.desktop.niri;
in
{
  options = {
    skyg.nixos.desktop.niri = {
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
      filePath = "niri.kdl";
      configSource = "/home/${config.skyg.user.name}/nixos-setup/configs/niri";
    };
  };
}
