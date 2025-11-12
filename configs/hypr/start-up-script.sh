#!/bin/sh

killall -q waybar
sleep 1

waybar --config /home/ari/nixos-setup/configs/hypr/waybar/bottom-bar.jsonc --style /home/ari/nixos-setup/configs/hypr/waybar/bottom-bar.css &
waybar --config /home/ari/nixos-setup/configs/hypr/waybar/top-bar.jsonc --style /home/ari/nixos-setup/configs/hypr/waybar/top-bar.css &
waypaper --restore

killall -q hypridle
hypridle &

killall -q swayosd-server
swayosd-server &
killall -q walker
walker --gapplication-service &

notify-send "Hyprland Startup Script" "Completed 🎉"
