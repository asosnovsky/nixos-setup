{ ... }:
{
  hardware.enableRedistributableFirmware = true;
  hardware.framework.enableKmod = true;
  hardware.graphics.enable = true;
  hardware.bluetooth.powerOnBoot = true;

  boot.binfmt.emulatedSystems = [ "aarch64-linux" ];

  services.fprintd.enable = true;
  services.libinput.enable = true;
  services.yubikey-agent.enable = true;

  skyg.nixos.common.hardware.bluetooth.enable = true;
}
