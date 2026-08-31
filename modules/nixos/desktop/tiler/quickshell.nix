{ config
, lib
, pkgs
, skygUtils
, ...
}:
let
  cfg = config.skyg.nixos.desktop.tiler.quickshell;
in
{
  options = {
    skyg.nixos.desktop.tiler.quickshell = {
      enable = lib.mkEnableOption "quickshell";
      configName = lib.mkOption {
        type = lib.types.str;
        default = config.skyg.core.hostName;
        description = ''
          Name of the per-host Quickshell config directory under `configs/`.
          The module symlinks `~/.config/quickshell` -> `configs/<configName>/quickshell`.
          Defaults to the machine's hostName (e.g. `fwbook` -> `configs/fwbook/quickshell`).
        '';
      };
    };
  };
  config = lib.mkIf cfg.enable {
    environment.systemPackages = [ pkgs.quickshell ];

    # Symlink ~/.config/quickshell -> configs/<configName>/quickshell (host-specific).
    system.userActivationScripts.quickshellCfg.text = skygUtils.makeHyperlinkScriptToConfigs {
      filePath = "${cfg.configName}/quickshell";
      targetPath = "quickshell";
      configSource = "/home/${config.skyg.user.name}/nixos-setup/configs";
    };
  };
}
