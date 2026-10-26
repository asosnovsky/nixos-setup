{ ... }:
{
  services.tailscale.enable = true;

  systemd.network.wait-online.ignoredInterfaces = [
    "hermes-br"
    "vm-hermes"
  ];
}
