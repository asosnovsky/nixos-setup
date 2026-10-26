{ ... }:
{
  services.tailscale.enable = true;

  systemd.network.wait-online.enable = false;
}
