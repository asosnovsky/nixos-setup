{ ... }:
{
  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;

  services.journald.extraConfig = ''
    SystemMaxUse=1G
  '';
}
