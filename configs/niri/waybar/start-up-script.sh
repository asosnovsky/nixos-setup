#!/bin/sh

killall -q waybar
sleep 1

waybar --config /home/ari/nixos-setup/configs/niri/waybar/bottom-bar.jsonc --style /home/ari/nixos-setup/configs/niri/waybar/bottom-bar.css &
waybar --config /home/ari/nixos-setup/configs/niri/waybar/top-bar.jsonc --style /home/ari/nixos-setup/configs/niri/waybar/top-bar.css &
waypaper --restore

killall -q hypridle
hypridle &

killall -q swayosd-server
swayosd-server

notify-send "Niri Startup Script" "Completed 🎉"
