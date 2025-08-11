set shell := ["zsh", "-cu"]

default:
  just --list

build:
    nh os build

switch:
    nh os switch

rollback:
    sudo nixos-rebuild switch --rollback

update input_name="":
    if [ ! -z {{input_name}} ]; then \
        cmd="nix flake update {{input_name}}"; \
    else \
        cmd="nix flake update"; \
    fi
    echo $cmd
    # $cmd
    git diff flake.lock

remote cmd target:
    ./bin/extra/build-remote-nixos {{target}} {{cmd}}