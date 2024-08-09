#!/bin/sh

if [ ! -f .locks/.built_via_skg ]; then
    ./build-nixos.sh
    echo "Do you want to continue? (y/N)"
    read -r answer
    if [[ $answer =~ ^[yY]$ ]]; then
        echo "Continuing..."
    else
        echo "Exiting."
        exit 1
    fi
fi

sudo nixos-rebuild switch --flake .
git cap
rm -f .locks/.built_via_skg
