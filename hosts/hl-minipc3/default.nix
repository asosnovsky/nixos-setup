{ ... }:
{
  imports = [
    ./hardware-configuration
    ./hardware.nix
    ./systemd.nix
  ];

  skyg.user.enable = true;
  skyg.nixos.common.ssh-server.enable = true;
  skyg.server.dns.routing = {
    enable = false;
    openFirewall = true;
    addressesSecretName = "dns-addresses.conf";
  };
  skyg.nixos.common.containers.openMetricsPort = true;
  skyg.server.exporters.enable = true;
  skyg.nixos.server.k3s = {
    enable = true;
    envPath = "/opt/k3s/k3s.env";
  };

  age.secrets.portainer-agent-minipc3.file = ../secrets/portainer-agent-minipc3.age;
  skyg.nixos.server.portainer = {
    enable = true;
    mode = "agent";
    agent.k3s = {
      enable = true;
      edgeKeySecretName = "portainer-agent-minipc3";
    };
  };

  networking.firewall.enable = false;
}
