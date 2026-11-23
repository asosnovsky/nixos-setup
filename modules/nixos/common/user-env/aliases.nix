{ config
, lib
, pkgs
, ...
}:
let
  # One list for zsh, bash and Nushell. Keep values to a plain command and
  # flags: they are copied into Nushell as-is, so pipes, $VARS or && break.
  aliases = {
    cat = "bat";
    ls = "eza";
    ll = "eza -l";
    la = "eza -a";
    lla = "eza -la";
    lt = "eza --tree";
    open-this = "xdg-open";
  };

  # Nushell loads every .nu file in share/nushell/vendor/autoload at startup.
  nushellAliases = pkgs.writeTextDir "share/nushell/vendor/autoload/skyg-aliases.nu"
    (lib.concatLines (lib.mapAttrsToList (name: value: "alias ${name} = ${value}") aliases));
in
{
  config = lib.mkIf config.skyg.user.enable {
    environment.shellAliases = aliases;
    environment.systemPackages = [ nushellAliases ];
    environment.pathsToLink = [ "/share/nushell" ];
  };
}
