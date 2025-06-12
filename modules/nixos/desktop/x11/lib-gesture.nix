{ config, lib, pkgs, ... }:
let
  cfg = config.skyg.nixos.desktop.x11;
in
{
  options = {
    skyg.nixos.desktop.x11 = {
      enableLibGestures = lib.mkEnableOption
        "Enable Desktop";
    };
  };
  config = lib.mkIf cfg.enableLibGestures {
    users.users.${config.skyg.user.name}.extraGroups = [ "input" ];
    environment.systemPackages = with pkgs; [
      # These are used to handle touchpad gestures
      libinput-gestures
      wmctrl
      xdotool
    ];
    system.userActivationScripts.hyprlandMineConfig.text = ''
      ln -sfn "/home/${config.skyg.user.name}/nixos-setup/configs/libinput-gestures.conf" "$HOME/.config/libinput-gestures.conf"
    '';
  };
}
