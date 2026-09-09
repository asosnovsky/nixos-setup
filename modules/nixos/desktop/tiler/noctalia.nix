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
  bakedConfig = skygUtils.bakeConfig {
    configName = cfg.configLink.name;
    configType = "noctalia";
  };
in
{
  options = {
    skyg.nixos.desktop.tiler.noctalia = {
      enable = lib.mkEnableOption "noctalia";
      configLink = skygUtils.makeConfigLinkOptions {
        hostName = config.skyg.core.hostName;
        configType = "noctalia";
      };
    };
  };
  config = lib.mkIf cfg.enable {
    environment.systemPackages = [ noctaliaPkg ] ++ (lib.optionals cfg.configLink.mountAsSource [ bakedConfig ]);

    # Symlink ~/.config/noctalia -> configs/<configName>/noctalia (host-specific).
    system.userActivationScripts.noctaliaCfg = lib.mkIf cfg.configLink.enable {
      text = skygUtils.makeHyperlinkScriptToConfigs {
        filePath = "${cfg.configLink.name}/noctalia";
        targetPath = "noctalia";
        configSource =
          if cfg.configLink.mountAsSource then
            "${bakedConfig}"
          else
            "/home/${config.skyg.user.name}/nixos-setup/configs";
      };
    };
  };
}
