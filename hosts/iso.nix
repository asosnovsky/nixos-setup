{ config, lib, pkgs, ... }:
{
  # Root access without password
  users.users.root.initialHashedPassword = "";
  security.sudo.wheelNeedsPassword = false;

  # Networking
  networking.networkmanager.enable = true;

  # SSH for remote installation
  services.openssh.enable = true;
  services.openssh.settings.PermitRootLogin = "yes";

  # GUI with lightweight desktop
  services.xserver.enable = true;
  services.xserver.displayManager.lightdm.enable = true;
  services.xserver.desktopManager.xfce.enable = true;

  # Core system packages
  environment.systemPackages = with pkgs; [
    # Disk tools
    parted
    gparted              # GUI partitioner
    cryptsetup
    btrfs-progs
    dosfstools
    ntfs3g
    e2fsprogs

    # Utilities
    curl
    wget
    git
    htop
    tmux

    # Documentation
    man-pages
  ];

  # Disable heavy services
  services.printing.enable = lib.mkForce false;
  sound.enable = lib.mkForce false;

  # Include documentation
  documentation.nixos.enable = true;
}
