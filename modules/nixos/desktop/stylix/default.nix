{ config, pkgs, lib, ... }:
let
  cfg = config.skyg.nixos.desktop.stylix;
in
{
  options = {
    skyg.nixos.desktop.stylix = {
      enable = (lib.mkEnableOption
        "Enable Stylix") // {
        default = true;
      };
    };
  };
  config = lib.mkIf (cfg.enable && config.skyg.nixos.desktop.enable) {
    stylix.enable = true;
    stylix.base16Scheme = "${pkgs.base16-schemes}/share/themes/gruvbox-dark-hard.yaml";
    stylix.polarity = "dark";
    stylix.autoEnable = true;
    stylix.fonts = {
      serif = {
        package = pkgs.dejavu_fonts;
        name = "DejaVu Serif";
      };

      sansSerif = {
        package = pkgs.dejavu_fonts;
        name = "DejaVu Sans";
      };

      monospace = {
        package = pkgs.dejavu_fonts;
        name = "DejaVu Sans Mono";
      };

      emoji = {
        package = pkgs.noto-fonts-color-emoji;
        name = "Noto Color Emoji";
      };
    };
  };
}
