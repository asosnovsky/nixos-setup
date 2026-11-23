# Shell and CLI setup for the main user and root (skyg.user.enable).
# Tools and anything needing a store path are NixOS options here; plain
# dotfiles live in configs/shared and are linked by skyg.configLinks.
{ ... }:
{
  imports = [
    ./packages.nix
    ./aliases.nix
    ./zsh.nix
    ./starship.nix
    ./nushell.nix
    ./git.nix
    ./neovim.nix
    ./tmux.nix
    ./zellij.nix
    ./direnv.nix
    ./bat.nix
    ./gnupg.nix
  ];
}
