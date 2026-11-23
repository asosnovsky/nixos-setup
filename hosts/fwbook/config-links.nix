{ ... }:
{
  # This machine has the repo at ~/nixos-setup: link to it so edits to
  # configs/ apply without a rebuild.
  skyg.configLinks.live = true;

  skyg.configLinks.links = {
    # Extra zsh functions, sourced by configs/shared/zsh/zshrc.
    zsh-host = {
      source = "fwbook/zsh";
      target = ".config/zsh";
    };
    # Default apps. Read-only so apps (e.g. Slack) cannot make themselves
    # the default handler; edit configs/fwbook/mimeapps.list and rebuild.
    mimeapps = {
      source = "fwbook/mimeapps.list";
      target = ".config/mimeapps.list";
      baked = true;
    };
    mimeapps-legacy = {
      source = "fwbook/mimeapps.list";
      target = ".local/share/applications/mimeapps.list";
      baked = true;
    };
  };
}
