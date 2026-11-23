{ pkgs, ... }:
{
  imports = [
    ./services
    ./hardware-configuration
    ./hardware.nix
    ./systemd.nix
  ];

  skyg = {
    user.enable = true;
    server.admin.enable = true;

    nixos = {
      common.ssh-server.enable = true;
      common.diagnix.enable = true;

      common.dns.enable = true;
      common.hardware = {
        nvidia.enable = true;
        amdgpu.enable = true;
        udevrules.coraltpu.enable = true;
      };
      server.services.ai.enable = true;
    };
    networkDrives.enable = true;
  };
  skyg.nixos.common.containers.networks.ipvlanLab = {
    enable = true;
    parent = "enp6s0";
  };
  networking.firewall.enable = false;
  users.users.ari.extraGroups = [ "input" ];

  environment.systemPackages = with pkgs; [
    nvidia-container-toolkit
    libnvidia-container
    docker
    runc
  ];
}
