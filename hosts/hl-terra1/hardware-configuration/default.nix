#
# Clanker ! Do not modify this file!
#
{ config, lib, pkgs, modulesPath, ... }:
let
  kernel = config.boot.kernelPackages.kernel;
  hddled = pkgs.stdenv.mkDerivation rec {
    name = "hddled_tmj33-${version}-${kernel.version}";
    version = "0.3";
    src = pkgs.fetchFromGitHub {
      owner = "arnarg";
      repo = "hddled_tmj33";
      rev = version;
      sha256 = "sha256-sQ8fLK8NP5sHw/9gJTO6lqgWfwmi1G5KDwWuWujNCZw=";
    };
    nativeBuildInputs = kernel.moduleBuildDependencies;
    preConfigure = ''
      sed -i 's|depmod|#depmod|' Makefile
    '';
    makeFlags = [
      "TARGET=${kernel.modDirVersion}"
      "KERNEL_MODULES=${kernel.dev}/lib/modules/${kernel.modDirVersion}"
      "MODDESTDIR=$(out)/lib/modules/${kernel.modDirVersion}/kernel/drivers/misc"
    ];
  };
in
{
  imports = [
    ./boot.nix
    ./file-system.nix
  ];
}
