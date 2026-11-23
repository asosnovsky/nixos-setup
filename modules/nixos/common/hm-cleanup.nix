# TEMPORARY: one-time cleanup after home-manager was removed.
{ config
, lib
, ...
}:
let
  cleanup = home: ''
    if [[ -d "${home}" && ! -e "${home}/.local/state/skyg-hm-cleanup-done" ]]; then
      for spec in ".:1" ".config:6" ".local/share:5" ".local/state:1" ".cache:1" ".gnupg:1" ".themes:1"; do
        dir="${home}/''${spec%%:*}"
        [[ -d "$dir" ]] || continue
        find "$dir" -maxdepth "''${spec##*:}" -type l \
          -lname '/nix/store/*-home-manager-files/*' -delete 2>/dev/null || true
      done
      rm -rf "${home}/.local/state/home-manager"
      rm -f "${home}"/.local/state/nix/profiles/home-manager*
      mkdir -p "${home}/.local/state"
      touch "${home}/.local/state/skyg-hm-cleanup-done"
    fi
  '';
in
{
  config = lib.mkIf config.skyg.user.enable {
    system.userActivationScripts.skygHmCleanup.text = cleanup "$HOME";
    system.activationScripts.skygRootHmCleanup.text = cleanup config.users.users.root.home;
  };
}
