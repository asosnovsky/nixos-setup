{ ... }:
{
  hardware.enableRedistributableFirmware = true;
  hardware.framework.enableKmod = true;
  hardware.graphics.enable = true;
  hardware.bluetooth.powerOnBoot = true;

  boot.binfmt.emulatedSystems = [ "aarch64-linux" ];

  # Reserve RAM for pstore/ramoops so a panic/oops backtrace survives a hard
  # reset even if the disk/journal never gets a chance to sync. Archived to
  # /var/lib/systemd/pstore on next boot by systemd-pstore.service.
  boot.kernelParams = [
    "reserve_mem=8M:4096:ramoops"
    "ramoops.mem_name=ramoops"
    "ramoops.console_size=0x400000"
    "ramoops.record_size=0x200000"
    "ramoops.dump_oops=1"
    "ramoops.ftrace_size=0"
    "ramoops.pmsg_size=0"
  ];

  services.fprintd.enable = true;
  services.libinput.enable = true;
  services.yubikey-agent.enable = true;

  skyg.nixos.common.hardware.bluetooth.enable = true;
}
