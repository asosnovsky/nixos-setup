{ pkgs, lib, rootDir }:
let
  # Shell snippet: make `target` a symlink to `source` (file or dir).
  # Makes the parent dir; a real file or dir in the way is kept as a backup.
  makeLinkScript =
    { source
    , target
    }: ''
      mkdir -p "$(dirname "${target}")"
      if [[ -e "${target}" && ! -L "${target}" ]]; then
        mv "${target}" "${target}.backup.$(date +%Y_%m_%d_%H_%M_%S)"
      fi
      ln -sfn "${source}" "${target}"
    '';
in
{
  bakeConfig =
    { configName
    , configType
    }: pkgs.stdenv.mkDerivation {
      pname = "skyg-${configName}-${configType}-config";
      version = "1";
      src = "${rootDir}/configs/${configName}/${configType}";
      buildPhase = "true";
      installPhase = ''
        mkdir -p "$out/${configName}"
        cp -r "$src" "$out/${configName}/${configType}"
      '';
    };
  inherit makeLinkScript;
  makeHyperlinkScriptToConfigs =
    { filePath
    , configSource
    , targetPath ? filePath
    }: makeLinkScript {
      source = "${configSource}/${filePath}";
      target = "$HOME/.config/${targetPath}";
    };
  makeConfigLinkOptions =
    { configType
    , hostName
    }: {
      enable = lib.mkOption {
        type = lib.types.bool;
        default = true;
        description = ''
          	          Whether to symlink `~/.config/${configType}` -> `configs/<configName>/${configType}`.
          	          Disable on hosts that manage their own ${configType} config elsewhere.
          	        '';
      };
      name = lib.mkOption {
        type = lib.types.str;
        default = hostName;
        description = ''
          	          Name of the per-host ${configType} config directory under `configs/`.
          	          The module symlinks `~/.config/${configType}` -> `configs/<configName>/${configType}`.
          	          Defaults to the machine's hostName (e.g. `fwbook` -> `configs/fwbook/${configType}`).
          	        '';
      };
      mountAsSource = lib.mkOption {
        type = lib.types.bool;
        default = false;
        description = ''
          If `configLink.enable` is true, embed the config dir in the build.
          A GC-protected copy of the config is baked into the system closure
          (via a derivation added to the system profile) instead of symlinking
          to the live `~/nixos-setup/configs` checkout, making the config part
          of the built system and reproducible.
        '';
      };
    };
  container-services = rec {
    makeNfsVolumeFactory = host: exportPath: {
      driver_opts = {
        type = "nfs";
        o = "addr=${host},rw,nfsvers=4.0,nolock,hard,noatime";
        device = ":${exportPath}";
      };
    };
    nfsVols = {
      terra1 = makeNfsVolumeFactory "terra1.lab.internal";
      tnas1 = makeNfsVolumeFactory "tnas1.lab.internal";
      bigbox2 = makeNfsVolumeFactory "bigbox2.lab.internal";
    };
  };
}
