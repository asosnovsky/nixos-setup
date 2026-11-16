{ pkgs, unstablePkgs, ... }:
let
  slack = unstablePkgs.slack;
  slackIcon = "${slack}/share/icons/hicolor/512x512/apps/slack.png";
  makeSlack =
    { id, name, color }:
    let
      icon = pkgs.runCommand "slack-${id}-icon.png" { nativeBuildInputs = [ pkgs.imagemagick ]; } ''
        magick ${slackIcon} -modulate 100,0 -fill '${color}' -tint 100 $out
      '';
      bin = pkgs.writeShellScriptBin "slack-${id}" ''
        exec ${slack}/bin/slack --user-data-dir="''${XDG_CONFIG_HOME:-$HOME/.config}/Slack-${name}" "$@"
      '';
      desktop = pkgs.makeDesktopItem {
        name = "slack-${id}";
        desktopName = "Slack (${name})";
        exec = "${bin}/bin/slack-${id} -s %U";
        inherit icon;
        startupWMClass = "Slack";
        categories = [ "Network" "InstantMessaging" ];
      };
    in
    pkgs.symlinkJoin {
      name = "slack-${id}";
      paths = [ bin desktop ];
    };
  slack-sibli = makeSlack { id = "sibli"; name = "Sibli"; color = "#2EB67D"; };
  slack-personal = makeSlack { id = "personal"; name = "Personal"; color = "#4A154B"; };

  # Opens slack:// links in the Slack you pick.
  slack-link-picker =
    let
      bin = pkgs.writeShellScriptBin "slack-link-picker" ''
        choice=$(printf '%s\n' "Slack" "Slack (Sibli)" "Slack (Personal)" \
          | ${pkgs.rofi}/bin/rofi -dmenu -i -p "Open Slack link in")
        case "$choice" in
          "Slack") exec ${slack}/bin/slack -s "$@" ;;
          "Slack (Sibli)") exec ${slack-sibli}/bin/slack-sibli -s "$@" ;;
          "Slack (Personal)") exec ${slack-personal}/bin/slack-personal -s "$@" ;;
        esac
      '';
      desktop = pkgs.makeDesktopItem {
        name = "slack-link-picker";
        desktopName = "Slack Link Picker";
        exec = "${bin}/bin/slack-link-picker %U";
        icon = "slack";
        noDisplay = true;
        mimeTypes = [ "x-scheme-handler/slack" ];
      };
    in
    pkgs.symlinkJoin {
      name = "slack-link-picker";
      paths = [ bin desktop ];
    };
in
{
  environment.systemPackages = [
    slack-sibli
    slack-personal
    slack-link-picker
  ];
}
