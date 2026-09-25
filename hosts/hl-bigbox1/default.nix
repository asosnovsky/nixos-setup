{ pkgs, config, ... }:
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
    server.exporters.enable = true;
    nixos = {
      desktop = {
        enable = false;
        gnome.enable = false;
      };
      common.ssh-server.enable = true;
      common.containers.openMetricsPort = true;
      common.hardware = {
        nvidia.enable = true;
        amdgpu.enable = true;
        udevrules.coraltpu.enable = true;
      };
      server.services.ai.enable = true;
    };
    networkDrives.enable = true;
  };

  services.displayManager.defaultSession = "gnome";
  services.displayManager.autoLogin = {
    enable = true;
    user = config.skyg.user.name;
  };
  services.displayManager.gdm.autoSuspend = false;
  services.displayManager.gdm.autoLogin.delay = 0;

  networking.firewall.enable = false;
  users.users.ari.extraGroups = [ "input" ];

  environment.systemPackages = with pkgs; [
    nvidia-container-toolkit
    libnvidia-container
    docker
    runc
  ];
}
