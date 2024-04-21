{ pkgs, ... }:

{
  languages.nix.enable = true;
  packages = [
    pkgs.nixpkgs-fmt
  ];
  pre-commit = {
    hooks.nixpkgs-fmt.enable = true;
  };
}
