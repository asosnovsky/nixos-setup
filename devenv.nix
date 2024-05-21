{ pkgs, ... }:

{
  languages.nix.enable = true;
  packages = [
    pkgs.nixpkgs-fmt
    pkgs.nixd
  ];
  pre-commit = {
    hooks.nixpkgs-fmt.enable = true;
  };
}
