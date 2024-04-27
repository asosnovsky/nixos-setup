{ hostName, firewall }:
{ pkgs, ... }:
{
  # Define your hostname.
  networking.hostName = hostName;

  # Enable networking
  networking.networkmanager.enable = true;
  networking.firewall = firewall;

  # NFS Support
  services.nfs.server.enable = true;

  # Tailscale
  services.tailscale.enable = true;
  services.tailscale.useRoutingFeatures = "client";
}
