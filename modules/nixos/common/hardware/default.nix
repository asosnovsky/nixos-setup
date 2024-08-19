{ ... }:
{
  imports = [
    ./fan2go.nix
    ./fancontrol.nix
    ./sound.nix
    ./bluetooth.nix
  ];
  # Firmware Updater
  services.fwupd.enable = true;
  # Enable all license firmware
  hardware.enableAllFirmware = true;



  # Yubikey
  services.yubikey-agent.enable = true;

  # Enable CUPS to print documents.
  services.printing.enable = true;
}
