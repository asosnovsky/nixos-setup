{ pkgs ? import <nixpkgs> {} }:
  pkgs.mkShell {
    name = "yubissh";
    nativeBuildInputs = [
	pkgs.yubikey-manager
	pkgs.yubico-piv-tool	
    ];
}
