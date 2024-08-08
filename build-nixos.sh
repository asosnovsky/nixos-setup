#!/bin/sh

rm -f .built_via_skg
sudo nixos-rebuild build --flake .
touch .built_via_skg
nvd diff /run/current-system result