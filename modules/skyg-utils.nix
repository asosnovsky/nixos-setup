{ pkgs, lib }:
{
  makeHyperlinkScriptToConfigs =
    { filePath
    , configSource
      # Where the symlink is created under ~/.config. Defaults to filePath so
      # existing callers keep linking ~/.config/<filePath> -> <configSource>/<filePath>.
      # Set this when the source lives under a subdir but should surface at a
      # flatter ~/.config path, e.g. filePath = "fwbook/hypr", targetPath = "hypr".
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
}
