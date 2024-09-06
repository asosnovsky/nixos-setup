{ pkgs }:
with pkgs;
{
  theme = {
    name = "WhiteSur-Dark";
    package = whitesur-gtk-theme;
  };
  font = {
    name = "FiraCode";
    package = fira-code;
    size = 8;
  };
}
