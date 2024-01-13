{ enableFingerPrint ? false }:
{ pkgs, ... }:
{
  # Firmware Updater
  services.fwupd.enable = true;
  services.fprintd = if enableFingerPrint then {
    enable = true;
    # tod.enable = true;
    # tod.driver = pkgs.libfprint-2-tod1-goodix;
  } else {

  };
}