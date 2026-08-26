{ config
, lib
, pkgs
, skygUtils
, noctalia
, ...
}:
let
  cfg = config.skyg.nixos.desktop.tiler.noctalia;
  system = pkgs.stdenv.hostPlatform.system;
  noctaliaPkg = noctalia.packages.${system}.default;
in
{
  options = {
    skyg.nixos.desktop.tiler.noctalia = {
      enable = lib.mkEnableOption "noctalia";
      configName = lib.mkOption {
        type = lib.types.str;
        default = config.skyg.core.hostName;
        description = ''
          Name of the per-host noctalia config directory under `configs/`.
          The module symlinks `~/.config/noctalia` -> `configs/<configName>/noctalia`.
          Defaults to the machine's hostName (e.g. `fwbook` -> `configs/fwbook/noctalia`).
        '';
      };
    };
  };
  config = lib.mkIf cfg.enable {
    environment.systemPackages = [ noctaliaPkg ];

    # Symlink ~/.config/noctalia -> configs/<configName>/noctalia (host-specific).
    system.userActivationScripts.noctaliaCfg.text = skygUtils.makeHyperlinkScriptToConfigs {
      filePath = "${cfg.configName}/noctalia";
      targetPath = "noctalia";
      configSource = "/home/${config.skyg.user.name}/nixos-setup/configs";
    };
  };
}
