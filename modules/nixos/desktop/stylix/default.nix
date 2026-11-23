{ config, pkgs, lib, ... }:
let
  cfg = config.skyg.nixos.desktop.stylix;
  # A read-only link from configs/shared/theme into the home dir.
  themeLink = source: target: {
    source = "shared/theme/${source}";
    inherit target;
    baked = true;
  };
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

    # Stylix themes the system (console, boot, fonts, Qt platform). The GTK
    # and Qt app themes below are a fixed copy of what it used to generate
    # for gruvbox-dark-hard; they do not follow base16Scheme.
    environment.systemPackages = [ pkgs.adw-gtk3 ];
    programs.dconf.profiles.user.databases = [{
      settings."org/gnome/desktop/interface" = {
        color-scheme = "prefer-dark";
        gtk-theme = "adw-gtk3";
      };
    }];
    skyg.configLinks.links = lib.mkIf config.skyg.user.enable {
      theme-gtk2 = themeLink "gtk/gtkrc-2.0" ".gtkrc-2.0";
      theme-gtk3-css = themeLink "gtk/gtk.css" ".config/gtk-3.0/gtk.css";
      theme-gtk3-settings = themeLink "gtk/settings.ini" ".config/gtk-3.0/settings.ini";
      theme-gtk4-css = themeLink "gtk/gtk.css" ".config/gtk-4.0/gtk.css";
      theme-gtk4-settings = themeLink "gtk/settings.ini" ".config/gtk-4.0/settings.ini";
      theme-kvantum = themeLink "Kvantum/kvantum.kvconfig" ".config/Kvantum/kvantum.kvconfig";
      theme-kvantum-config = themeLink "Kvantum/Base16Kvantum/Base16Kvantum.kvconfig" ".config/Kvantum/Base16Kvantum/Base16Kvantum.kvconfig";
      theme-kvantum-svg = themeLink "Kvantum/Base16Kvantum/Base16Kvantum.svg" ".config/Kvantum/Base16Kvantum/Base16Kvantum.svg";
      theme-qt5ct = themeLink "qtct.conf" ".config/qt5ct/qt5ct.conf";
      theme-qt6ct = themeLink "qtct.conf" ".config/qt6ct/qt6ct.conf";
    };
  };
}
