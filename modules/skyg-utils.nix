{ pkgs, lib, rootDir }:
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
  makeHyperlinkScriptToConfigs =
    { filePath
    , configSource
    , targetPath ? filePath
    }:
    let
      homePath = "$HOME/.config/${targetPath}";
      sourcePath = "${configSource}/${filePath}";
    in
    ''
      rm -f "${homePath}"
      if [[ ! -h "${homePath}" ]]; then
        ln -s "${sourcePath}" "${homePath}" || {
          echo "Failed to create symlink for ${filePath} at ${homePath}"
          exit 1
        }
      fi
    '';
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
}
