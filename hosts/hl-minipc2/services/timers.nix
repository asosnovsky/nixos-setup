{ pkgs, ... }:
{
  skyg.server.timers.scrypted-backups = {
    OnCalendar = "daily";
    wantedBy = [ "homelab-terra1-Data-apps.mount" ];
    script = ''
      set -eu
      ${pkgs.rsync}/bin/rsync -avpzP --delete /opt/homelab/scrypted /homelab/terra1/Data/apps/
    '';
  };
}
