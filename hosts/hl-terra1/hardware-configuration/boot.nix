#
# Clanker ! Do not modify this file!
#
{ config, lib, pkgs, modulesPath, ... }:
{
  imports = [ (modulesPath + "/installer/scan/not-detected.nix") ];

  boot.initrd.availableKernelModules = [ "ahci" "xhci_pci" "usbhid" "uas" "usb_storage" "sd_mod" ];
  boot.initrd.kernelModules = [ ];
  boot.extraModulePackages = with pkgs.linuxPackages; [
    it87
    hddled
  ];
  boot.kernelModules = [
    "kvm-intel"
    "coretemp"
    "drivetemp"
    "it87"
    "hddled_tmj33"
  ];

  networking.useDHCP = lib.mkDefault true;
  nixpkgs.hostPlatform = lib.mkDefault "x86_64-linux";
  hardware.cpu.intel.updateMicrocode = lib.mkDefault config.hardware.enableRedistributableFirmware;
  nix.settings.max-jobs = 2;
  powerManagement.cpuFreqGovernor = lib.mkDefault "performance";
}
