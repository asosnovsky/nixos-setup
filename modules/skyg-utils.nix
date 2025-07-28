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
        ln -s "${sourcePath}" "${homePath}"
      fi
    '';
}
