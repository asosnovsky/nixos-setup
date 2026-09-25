{ pkgs, ... }:
{
  skyg.server.timers.jellyfin-backups = {
    OnCalendar = "daily";
    wantedBy = [ "homelab-terra1-Data-apps.mount" ];
    script = ''
      set -eu
      ${pkgs.rsync}/bin/rsync -avpzP --delete /opt/jellyfin /homelab/terra1/Data/apps/
    '';
  };
}
