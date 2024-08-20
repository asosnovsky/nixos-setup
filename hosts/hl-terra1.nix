{ user }:
{ pkgs, lib, config, ... }:
let
  openPorts = [
    # nfs
    111
    2049
    4000
    4001
    4002
    20048
    # ssh
    22
  ];
in
{
  imports = [ ./hl-terra1.hardware-configuration.nix ];
  skyg.user.enabled = true;
  skyg.nixos.common.ssh-server.enabled = true;
  # firmware updater
  services.fwupd.enable = true;
  # Bootloader.
  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;
  environment.systemPackages = with pkgs; [
    btrfs-progs
  ];
  # Firewall
  networking.firewall.allowedUDPPorts = openPorts;
  networking.firewall.allowedTCPPorts = openPorts;
  # NFS
  services.nfs.server = {
    enable = true;
    lockdPort = 4001;
    mountdPort = 4002;
    statdPort = 4000;
    extraNfsdConfig = '''';
    exports = ''
      /mnt/Data/apps  10.0.0.0/16(rw,wdelay,insecure,no_root_squash,no_subtree_check,sec=sys,rw,insecure,no_root_squash,no_all_squash)
    '';
  };
}

