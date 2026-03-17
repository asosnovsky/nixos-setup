{ config, lib, pkgs, modulesPath, ... }:

{
  imports =
    [ (modulesPath + "/installer/scan/not-detected.nix")
    ];

  boot.initrd.availableKernelModules = [ "ahci" "ohci_pci" "ehci_pci" "pata_atiixp" "xhci_pci" "usb_storage" "usbhid" "sd_mod" ];
  boot.initrd.kernelModules = [ ];
  boot.kernelModules = [ "kvm-amd" ];
  boot.extraModulePackages = [ ];

  fileSystems."/" =
    { device = "/dev/disk/by-uuid/6f050bcc-7579-48a9-b535-74076e78c5cd";
      fsType = "btrfs";
      options = [ "subvol=@root" ];
    };

  fileSystems."/boot" =
    { device = "/dev/disk/by-uuid/dab0ee8d-44b9-4b1e-b19a-01929f509820";
      fsType = "ext4";
    };

  fileSystems."/var" =
    { device = "/dev/disk/by-uuid/6f050bcc-7579-48a9-b535-74076e78c5cd";
      fsType = "btrfs";
      options = [ "compress=zstd" "subvol=@var" ];
    };

  fileSystems."/nix" =
    { device = "/dev/disk/by-uuid/8cd6e560-4db9-4cf1-8048-27a7c6308965";
      fsType = "btrfs";
      options = [ "compress=zstd" "subvol=@nix" ];
    };

  fileSystems."/home" =
    { device = "/dev/disk/by-uuid/6f4b2adc-5818-41ea-a4ba-720fb96b8f98";
      fsType = "btrfs";
      options = [ "compress=zstd" "subvol=@home" ];
    };

  fileSystems."/data/fourTerra" =
    { device = "/dev/sde1";
      fsType = "btrfs";
      options = [ "compress=zstd" "subvol=@data" ];
    };

  fileSystems."/home" =
    { device = "/dev/disk/by-uuid/6f4b2adc-5818-41ea-a4ba-720fb96b8f98";
      fsType = "btrfs";
      options = [ "compress=zstd" "subvol=@home" ];
    };

  fileSystems."/data/fourTerra" =
    { device = "/dev/sde1";
      fsType = "btrfs";
      options = [ "compress=zstd" "subvol=@data" ];
    };

  swapDevices = [ ];

  nixpkgs.hostPlatform = lib.mkDefault "x86_64-linux";
  hardware.cpu.amd.updateMicrocode = lib.mkDefault config.hardware.enableRedistributableFirmware;
}
