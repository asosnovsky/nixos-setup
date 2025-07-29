{
  makeHyperlinkScriptToConfigs =
    { filePath
    , configSource
    }:
    let
      homePath = "$HOME/.config/${filePath}";
      sourcePath = "${configSource}/${filePath}";
    in
    ''
      rm -f "${homePath}"
      if [[ ! -h "$HOME/.config/${filePath}" ]]; then
        ln -s "${sourcePath}" "${homePath}" || {
          echo "Failed to create symlink for ${filePath} at ${homePath}"
          exit 1
        }
      fi
    '';
}
