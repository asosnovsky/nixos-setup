{ pkgs, config, ... }:
let
  staticIp = ip: {
    lan = { ipv4_address = ip; };
  };
in
{
  imports = [
    ./services
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
  skyg.nixos.common.containers.networks.ipvlanLab = {
    enable = true;
    parent = "enp2s0";
    ipRange = "10.0.101.240/28";
  };
  skyg.nixos.common.containers.openMetricsPort = true;
  skyg.server.exporters.enable = true;
  skyg.networkDrives.enable = true;

  networking.firewall.enable = false;
}
