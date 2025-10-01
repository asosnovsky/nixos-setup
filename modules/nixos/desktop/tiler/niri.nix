{ config, lib, pkgs, skygUtils, system, nixpkgs-unstable, ... }:
let
  cfg = config.skyg.nixos.desktop.tiler.niri;
  # unstable = import nixpkgs-unstable {
  #   inherit system;
  #   config.allowUnfree = true;
  # };
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
      # unstable.niriswitcher
    ];
    system.userActivationScripts.niriConfig.text = skygUtils.makeHyperlinkScriptToConfigs {
      filePath = "niri";
      configSource = "/home/${config.skyg.user.name}/nixos-setup/configs";
    };
  };
}

