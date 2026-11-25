{ pkgs, config, nixpkgs-slack, ... }:
let
  rofiTheme = import ./rofi-theme.nix {
    colors = config.lib.stylix.colors;
    font = "${config.stylix.fonts.monospace.name} ${toString config.stylix.fonts.sizes.popups}";
  };
  slack = (import nixpkgs-slack {
    system = pkgs.stdenv.hostPlatform.system;
    config.allowUnfreePredicate = pkg: pkgs.lib.getName pkg == "slack";
  }).slack;
  slackIcon = "${slack}/share/icons/hicolor/512x512/apps/slack.png";
  makeSlack =
    { id, name, color, browserProfile }:
    let
      icon = pkgs.runCommand "slack-${id}-icon.png" { nativeBuildInputs = [ pkgs.imagemagick ]; } ''
        magick ${slackIcon} -modulate 100,0 -fill '${color}' -tint 100 $out
      '';
      # Slack opens links via xdg-open from PATH; this one pins web links to a Chromium profile.
      xdgOpen = pkgs.writeShellScriptBin "xdg-open" ''
        case "$1" in
          http://*|https://*|mailto:*) exec chromium --profile-directory="${browserProfile}" "$@" ;;
        esac
        exec ${pkgs.xdg-utils}/bin/xdg-open "$@"
      '';
      bin = pkgs.writeShellScriptBin "slack-${id}" ''
        export PATH="${xdgOpen}/bin:$PATH"
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
      inherit icon;
    };
  slack-sibli = makeSlack { id = "sibli"; name = "Sibli"; color = "#2EB67D"; browserProfile = "Profile 1"; };
  slack-personal = makeSlack { id = "personal"; name = "Personal"; color = "#4A154B"; browserProfile = "Default"; };

  # Opens slack:// links in the Slack you pick.
  slack-link-picker =
    let
      bin = pkgs.writeShellScriptBin "slack-link-picker" ''
        choice=$(printf '%s\0icon\x1f%s\n' \
          "Slack" "${slackIcon}" \
          "Slack (Sibli)" "${slack-sibli.icon}" \
          "Slack (Personal)" "${slack-personal.icon}" \
          | ${pkgs.rofi}/bin/rofi -dmenu -i -show-icons -theme-str '${rofiTheme}' -p "Open Slack link in")
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
