# Shared rofi dmenu theme for the link pickers. Stylix doesn't theme rofi
# without home-manager, so this reads the live base16 colors/fonts directly.
{ colors, font }:
let
  bg = "#${colors.base00-hex}";
  fg = "#${colors.base05-hex}";
  accent = "#${colors.base0D-hex}";
in
''
  configuration {
      show-icons: true;
      font: "${font}";
  }
  * {
      background: ${bg};
      foreground: ${fg};
      accent: ${accent};
  }
  window {
      background-color: @background;
      border: 2px;
      border-radius: 14px;
      border-color: @accent;
      padding: 12px;
      width: 440px;
  }
  mainbox {
      children: [ inputbar, listview ];
      spacing: 10px;
      background-color: @background;
  }
  inputbar {
      background-color: @background;
      text-color: @foreground;
      padding: 8px 12px;
      border-radius: 10px;
      border: 1px;
      border-color: @accent;
      children: [ prompt, entry ];
  }
  prompt {
      text-color: @accent;
      padding: 0px 8px 0px 0px;
  }
  entry {
      text-color: @foreground;
      placeholder-color: @foreground;
  }
  listview {
      background-color: @background;
      lines: 4;
      spacing: 6px;
  }
  element {
      background-color: @background;
      text-color: @foreground;
      padding: 8px 10px;
      border-radius: 8px;
      orientation: horizontal;
  }
  element-icon {
      size: 28px;
      padding: 0px 10px 0px 0px;
  }
  element normal.normal, element alternate.normal {
      background-color: @background;
      text-color: @foreground;
  }
  element selected.normal {
      background-color: @accent;
      text-color: @background;
  }
''
