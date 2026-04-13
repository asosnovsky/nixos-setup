{ config, lib, pkgs, modulesPath, ... }:

{
  imports =
    [
      (modulesPath + "/installer/scan/not-detected.nix")
    ];

  boot.initrd.availableKernelModules = [ "ahci" "ohci_pci" "ehci_pci" "pata_atiixp" "xhci_pci" "usb_storage" "usbhid" "sd_mod" ];
  boot.initrd.kernelModules = [ ];
  boot.kernelModules = [ "kvm-amd" ];
  boot.extraModulePackages = [ ];
  boot.loader.grub = {
    enable = true;
    device = "/dev/sdb"; # install GRUB to MBR
    efiSupport = false;
  };

  fileSystems."/" =
    {
      device = "/dev/disk/by-uuid/5bf4a352-412f-47e1-9455-68f3aa629722";
      fsType = "btrfs";
      options = [ "subvol=@root" "compress=zstd" "noatime" ];
    };

  fileSystems."/boot" =
    {
      device = "/dev/disk/by-uuid/ccc80fd2-b38b-412b-9988-12a3194a5b57";
      fsType = "ext4";
    };

  fileSystems."/var" =
    {
      device = "/dev/disk/by-uuid/5bf4a352-412f-47e1-9455-68f3aa629722";
      fsType = "btrfs";
      options = [ "compress=zstd" "subvol=@var" "noatime" ];
    };

  fileSystems."/nix" =
    {
      device = "/dev/disk/by-uuid/8cd6e560-4db9-4cf1-8048-27a7c6308965";
      fsType = "btrfs";
      options = [ "compress=zstd" "subvol=@nix" "noatime" ];
    };

  fileSystems."/home" =
    {
      device = "/dev/disk/by-uuid/6f4b2adc-5818-41ea-a4ba-720fb96b8f98";
      fsType = "btrfs";
      options = [ "compress=zstd" "subvol=@home" "noatime" ];
    };

  fileSystems."/data/fourTerra" =
    {
      device = "/dev/sde1";
      fsType = "btrfs";
      options = [ "compress=zstd" "subvol=@data" "noatime" ];
    };

  swapDevices = [ ];

  nixpkgs.hostPlatform = lib.mkDefault "x86_64-linux";
  hardware.cpu.amd.updateMicrocode = lib.mkDefault config.hardware.enableRedistributableFirmware;
}
