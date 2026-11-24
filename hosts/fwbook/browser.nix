{ pkgs, config, ... }:
let
  rofiTheme = import ./rofi-theme.nix {
    colors = config.lib.stylix.colors;
    font = "${config.stylix.fonts.monospace.name} ${toString config.stylix.fonts.sizes.popups}";
  };
  personalIcon = "${pkgs.chromium.browser}/share/icons/hicolor/128x128/apps/chromium.png";
  workIcon = pkgs.runCommand "browser-work-icon.png" { nativeBuildInputs = [ pkgs.imagemagick ]; } ''
    magick ${personalIcon} -modulate 100,0 -fill '#${config.lib.stylix.colors.base0D-hex}' -tint 100 $out
  '';
  # Opens http(s) links in the Chromium profile you pick.
  # Profile dirs: "Default" = Personal, "Profile 1" = Work.
  browser-link-picker =
    let
      bin = pkgs.writeShellScriptBin "browser-link-picker" ''
        choice=$(printf '%s\0icon\x1f%s\n' \
          "Personal" "${personalIcon}" \
          "Work" "${workIcon}" \
          | ${pkgs.rofi}/bin/rofi -dmenu -i -show-icons -theme-str '${rofiTheme}' -p "Open link in")
        case "$choice" in
          "Personal") exec chromium --profile-directory="Default" "$@" ;;
          "Work") exec chromium --profile-directory="Profile 1" "$@" ;;
        esac
      '';
      desktop = pkgs.makeDesktopItem {
        name = "browser-link-picker";
        desktopName = "Browser Link Picker";
        exec = "${bin}/bin/browser-link-picker %U";
        icon = "chromium";
        noDisplay = true;
        mimeTypes = [
          "x-scheme-handler/http"
          "x-scheme-handler/https"
        ];
      };
    in
    pkgs.symlinkJoin {
      name = "browser-link-picker";
      paths = [ bin desktop ];
    };
in
{
  environment.systemPackages = [ browser-link-picker ];
}
