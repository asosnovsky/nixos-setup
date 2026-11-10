{ ... }:
{
  systemd.services.systemd-udev-settle.enable = false;

  # Snapper needs a .snapshots subvolume in each snapshotted volume
  systemd.tmpfiles.rules = [
    "v /.snapshots 0750 root root -"
    "v /home/.snapshots 0750 root root -"
  ];
}
