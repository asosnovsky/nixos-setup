#!/bin/sh
_CONFIG_DIR="$HOME/.config/niri"

hypridle &
xwayland-satellite &
mako &
nm-applet --indicator &
waybar -c $_CONFIG_DIR/waybar/top-config.jsonc -s $_CONFIG_DIR/waybar/style.css &
waybar -c $_CONFIG_DIR/waybar/bottom-config.jsonc -s $_CONFIG_DIR/waybar/style.css &
flatpak run dev.deedles.Trayscale --hide-window &