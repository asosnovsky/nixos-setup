{ pkgs, ... }:
{
  # Let nix's git fetches of private GitHub repos use the `gh auth login` token.
  programs.git = {
    enable = true;
    config.credential."https://github.com".helper = "!${pkgs.gh}/bin/gh auth git-credential";
  };
}
