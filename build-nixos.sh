#!/bin/sh

mkdir -p .locks
rm -f .locks/.built_via_skg
sudo nixos-rebuild build --flake .
touch .locks/.built_via_skg
nvd diff /run/current-system result