{ config, lib, pkgs, ... }:
let
  cfg = config.skyg.nixos.desktop;
in
{
  config = lib.mkIf cfg.enabled {
    services.xserver = {
      enable = true;
      xkb.layout = "us";
      xkb.variant = "";
    };
    environment.systemPackages = with pkgs; [
      # These are used to handle touchpad gestures
      libinput-gestures
      wmctrl
      xdotool
    ];
    system.userActivationScripts.hyprlandMineConfig.text = ''
      rm -f "$HOME/.config/libinput-gestures.conf"
      if [[ ! -h "$HOME/.config/libinput-gestures.conf" ]]; then
        ln -s "/home/${config.skyg.user.name}/nixos-setup/configs/libinput-gestures.conf" "$HOME/.config/libinput-gestures.conf"
      fi
    '';
  };
}
