{ pkgs, ... }:
let
  # Opens http(s) links in the Chromium profile you pick.
  # Profile dirs: "Default" = Personal, "Profile 1" = Work.
  browser-link-picker =
    let
      bin = pkgs.writeShellScriptBin "browser-link-picker" ''
        choice=$(printf '%s\n' "Personal" "Work" \
          | ${pkgs.rofi}/bin/rofi -dmenu -i -p "Open link in")
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
