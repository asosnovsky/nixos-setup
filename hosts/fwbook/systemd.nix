{ ... }:
{
  systemd.services.systemd-udev-settle.enable = false;

  systemd.tmpfiles.rules = [
    # Snapper needs a .snapshots subvolume in each snapshotted volume
    "v /.snapshots 0750 root root -"
    "v /home/.snapshots 0750 root root -"
    # Clear nix-shell leftovers in /tmp (a tmpfs) unused for a day
    "e /tmp/nix-shell.* - - - 1d"
  ];

  # Cap the desktop portal; it leaked to 19.6 GB and was OOM-killed on 2026-11-22.
  # At the cap it is killed, with no swap first, and D-Bus starts it again.
  systemd.user.services.xdg-desktop-portal.serviceConfig = {
    MemoryMax = "1G";
    MemorySwapMax = "0";
  };
}
