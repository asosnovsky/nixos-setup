#!/bin/sh

killall -q waybar

waybar --config /home/ari/nixos-setup/configs/niri/waybar/bottom-bar.jsonc --style /home/ari/nixos-setup/configs/niri/waybar/bottom-bar.css &
waybar --config /home/ari/nixos-setup/configs/niri/waybar/top-bar.jsonc --style /home/ari/nixos-setup/configs/niri/waybar/top-bar.css &
waypaper --restore