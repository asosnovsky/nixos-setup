{ pkgs, ... }:
let
  openPorts = [
    111
    2049
    4000
    4001
    4002
    20048
    22
    9090
  ];
in
{
  imports = [
    ./services.nix
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
  skyg.nixos.desktop.enable = false;
  skyg.server.admin.enable = true;
  skyg.server.exporters.enable = true;

  environment.systemPackages = with pkgs; [ btrfs-progs ];

  networking.firewall.allowedUDPPorts = openPorts;
  networking.firewall.allowedTCPPorts = openPorts;
}
