#!/bin/sh
mkdir -p results

nix flake show --json | jq -r -c '.nixosConfigurations | keys[]' | while read i; do
    echo "[[SKYG]] Building current $i"
    sudo nixos-rebuild build --flake .#$i
    rm -f results/$i-result
    mv result results/$i-result
done

nix flake update

rm -f diffs
mkdir diffs
nix flake show --json | jq -r -c '.nixosConfigurations | keys[]' | while read i; do
    echo "[[SKYG]] Building new $i"
    sudo nixos-rebuild build --flake .#$i
    rm -f results/$i-result-post
    mv result results/$i-result-post
    nvd diff results/$i-result results/$i-result-post > diffs/$i
done

