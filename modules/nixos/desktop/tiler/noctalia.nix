{ config
, lib
, pkgs
, skygUtils
, noctalia
, unstablePkgs
, ...
}:
let
  cfg = config.skyg.nixos.desktop.tiler.noctalia;
  system = pkgs.stdenv.hostPlatform.system;
  # Pull libqalculate from nixpkgs-unstable: stable 26.05 ships 5.10.0, which
  # segfaults in clear_randstate on Noctalia teardown when the launcher
  # calculator was never used. The null-check landed in 5.11.0 (unstable has it).
  # callPackage already folded libqalculate into buildInputs, so swap that entry.
  noctaliaPkg =
    let base = noctalia.packages.${system}.default; in
    base.overrideAttrs (old: {
      buildInputs = lib.map
        (p: if p.pname == "libqalculate" then unstablePkgs.libqalculate else p)
        old.buildInputs;
    });
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
