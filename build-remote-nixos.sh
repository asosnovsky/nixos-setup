#!/bin/sh
export NIX_SSHOPTS="-o RequestTTY=force"

target=${1}
target_host=root@$target.lab.internal
profile=hl-$target

valid_profiles=$(nix flake show --json | jq -r -c '.nixosConfigurations | keys[]' | grep "hl")

function print_valid_targets {
    echo "valid targets:"
    while IFS= read -r line; do
        echo $line | sed -r 's/.*hl-/ - /g'
    done <<< "$valid_profiles"
}

if [ -z $target ]; then
    echo "must specify a target!"
    print_valid_targets
    exit 1
fi

if echo "$valid_profiles" | grep -qFx "$profile"; then
    echo "Using [$profile]"
else
    echo "Invalid target! '$profile'"
    print_valid_targets
    exit 1
fi

function run {
    cmd=${1}
    echo "$cmd on $target_host with $profile through $build_host"
    nixos-rebuild \
    --target-host $target_host \
    --use-remote-sudo \
    $cmd \
    --flake \
    .#$profile
}

valid_cmds=( build switch test dry-activate )

cmd=${2}
case $cmd in
    "test" | "dry-activate" | "run" | "switch") run $cmd;;
    "build") 
        output=$(run $cmd)
        echo $output
        echo "_"
        echo $output | grep "nixos"
        echo "_"
        ;;
    *) 
        echo "invalid command"
        exit 1
        ;;
esac
