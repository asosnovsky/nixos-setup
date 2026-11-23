{ config
, lib
, pkgs
, ...
}:
let
  # Nushell plugin registry with the polars plugin added.
  nuPluginRegistry = pkgs.runCommandLocal "nu-plugin.msgpackz" { } ''
    export HOME="$TMPDIR"
    touch config.nu env.nu
    ${pkgs.nushell}/bin/nu \
      --config config.nu \
      --env-config env.nu \
      --plugin-config plugin.msgpackz \
      --no-history \
      --no-std-lib \
      --commands 'plugin add ${pkgs.nushellPlugins.polars}/bin/nu_plugin_polars'
    cp plugin.msgpackz "$out"
  '';
in
{
  config = lib.mkIf config.skyg.user.enable {
    environment.systemPackages = [ pkgs.nushell ];

    skyg.configLinks.links = {
      nushell = {
        source = "shared/nushell/config.nu";
        target = ".config/nushell/config.nu";
        root = true;
      };
      nushell-plugins = {
        storePath = nuPluginRegistry;
        target = ".config/nushell/plugin.msgpackz";
        root = true;
      };
    };
  };
}
