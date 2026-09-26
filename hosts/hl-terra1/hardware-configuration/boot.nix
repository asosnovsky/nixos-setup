#
# Clanker ! Do not modify this file!
#
{ config, lib, pkgs, modulesPath, ... }:
let
  kernel = config.boot.kernelPackages.kernel;
  hddled = pkgs.stdenv.mkDerivation rec {
    name = "hddled_tmj33-${version}-${kernel.version}";
    version = "0.3";

    src = pkgs.fetchFromGitHub {
      owner = "arnarg";
      repo = "hddled_tmj33";
      rev = version;
      sha256 = "sha256-sQ8fLK8NP5sHw/9gJTO6lqgWfwmi1G5KDwWuWujNCZw=";
    };

    nativeBuildInputs = kernel.moduleBuildDependencies;

    preConfigure = ''
      sed -i 's|depmod|#depmod|' Makefile
    '';

    makeFlags = [
      "TARGET=${kernel.modDirVersion}"
      "KERNEL_MODULES=${kernel.dev}/lib/modules/${kernel.modDirVersion}"
      "MODDESTDIR=$(out)/lib/modules/${kernel.modDirVersion}/kernel/drivers/misc"
    ];
  };
in
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
