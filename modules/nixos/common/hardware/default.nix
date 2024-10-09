{ ... }:
{
  imports = [
    ./fan2go.nix
    ./fancontrol.nix
    ./sound.nix
    ./laptop-power.nix
  ];
  # Firmware Updater
  services.fwupd.enable = true;
  # Enable all license firmware
  hardware.enableAllFirmware = true;
}
