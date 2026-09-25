{ ... }:
{
  services.tailscale.enable = false;
  services.tailscale.disableTaildrop = true;
  services.tailscale.useRoutingFeatures = "both";
  services.tailscale.openFirewall = true;
}
