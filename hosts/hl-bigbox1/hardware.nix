{ pkgs, ... }:
{
  services.fwupd.enable = true;
  boot.binfmt.emulatedSystems = [ "aarch64-linux" ];
  boot.kernelPackages = pkgs.linuxPackages;
  networking.interfaces.enp4s0.wakeOnLan.enable = true;
  networking.interfaces.lo.wakeOnLan.enable = true;
}
