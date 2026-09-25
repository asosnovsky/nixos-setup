{ config, lib, pkgs, ... }:
{
  users.users.root.initialHashedPassword = "";
  security.sudo.wheelNeedsPassword = false;
  users.users.root.shell = lib.mkForce pkgs.bash;

  networking.networkmanager.enable = true;

  skyg = {
    user.enable = true;
    nixos.common.ssh-server.enable = true;
  };

  services.openssh.settings.PermitRootLogin = "yes";

  environment.systemPackages = with pkgs; [
    parted
    gparted
    cryptsetup
    btrfs-progs
    dosfstools
    ntfs3g
    e2fsprogs
    curl
    wget
    git
    htop
    zellij
    man-pages
  ];

  documentation.nixos.enable = true;
}
