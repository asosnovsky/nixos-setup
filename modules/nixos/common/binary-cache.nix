{ config, lib, pkgs, ... }:
let
  cfg = config.skyg.nixos.common.cachePush;
in
{
  options.skyg.nixos.common.cachePush = {
    enable = lib.mkEnableOption "push finished builds to the bigbox2 binary cache";
    url = lib.mkOption {
      type = lib.types.str;
      default = "http://bigbox2.lab.internal:5000";
    };
  };

  config = lib.mkIf cfg.enable {
    # Push every finished build to the cache right after it finishes.
    nix.settings.post-build-hook = pkgs.writeShellScript "nix-post-build-hook" ''
      set -u
      if [ -n "''${OUT_PATHS:-}" ]; then
        nix copy --to "${cfg.url}" $OUT_PATHS \
          || echo "post-build-hook: failed to push to ${cfg.url}" >&2
      fi
    '';

    # Manual/backstop push command, available on every host's PATH.
    environment.systemPackages = [
      (pkgs.writeShellScriptBin "push-cache" ''
        set -eu
        if [ "''$#" -eq 0 ]; then
          set -- /run/current-system
        fi
        exec nix copy --to "${cfg.url}" "''$@"
      '')
    ];
  };
}
