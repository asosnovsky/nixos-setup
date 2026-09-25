#
# Clanker ! Do not modify this file!
#
{ config, lib, pkgs, modulesPath, ... }:
{
  imports = [ (modulesPath + "/installer/scan/not-detected.nix") ];

  boot.initrd.availableKernelModules =
    [ "nvme" "xhci_pci" "thunderbolt" "uas" "sd_mod" ];
  boot.initrd.kernelModules = [ ];
  boot.kernelModules = [ "kvm-amd" ];
  boot.kernelPackages = pkgs.linuxPackages_latest;
  boot.kernelParams = [
    "quiet"
    "splash"
    "boot.shell_on_fail"
    "udev.log_priority=3"
    "rd.systemd.show_status=auto"
    # Improve s2idle sleep behavior on AMD
    "rtc_cmos.use_acpi_alarm=1"
    "acpi.prefer_microsoft_dsm_guid=1"
    "amd_pstate=active"
    # Disable the old and new display power-saving features (PSR and Panel Replay).
    "amdgpu.dcdebugmask=0x410"
  ];
  boot.extraModulePackages = [ ];
  boot.plymouth = {
    enable = true;
  };
  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;
  boot.tmp.useTmpfs = true;
  boot.consoleLogLevel = 3;
  boot.initrd.verbose = false;
  boot.extraModprobeConfig = ''
    options snd_hda_intel power_save=0
  '';

  boot.kernel.sysctl = {
    "vm.swappiness" = 150;
    "vm.page-cluster" = 0;
  };
  networking.useDHCP = lib.mkDefault true;
  nixpkgs.hostPlatform = lib.mkDefault "x86_64-linux";
  hardware.cpu.amd.updateMicrocode =
    lib.mkDefault config.hardware.enableRedistributableFirmware;
}
