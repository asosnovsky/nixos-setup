{ lib, pkgs, determinate, ... }:
{
  skyg.user.enable = true;
  skyg.nixos.common.ssh-server.enable = true;

  # Determinate Nix builds its own Nix from source (no aarch64-linux binary
  # cache hit for us), and its test suite fails under QEMU emulation because
  # nested seccomp doesn't work through the translation layer. Skip the test
  # suite for this build only — Determinate Nix itself stays enabled.
  nix.package = lib.mkForce (
    determinate.inputs.nix.packages.${pkgs.stdenv.system}.default.overrideAttrs (old: {
      doCheck = false;
    })
  );

  # CM4 boots via Pi firmware + U-Boot reading extlinux.conf (set up by the
  # official NixOS SD image) — not systemd-boot/EFI like the other hosts.
  boot.loader.grub.enable = false;
  boot.loader.generic-extlinux-compatible.enable = true;

  # Serial console, useful for headless debugging over UART.
  boot.kernelParams = [ "console=ttyS0,115200n8" "console=tty0" ];

  # SD image has no swap partition; use compressed RAM swap instead.
  zramSwap.enable = true;
}
