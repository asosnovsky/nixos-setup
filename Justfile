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
        echo "just updating... {{input_name}}"; \
        nix flake update {{input_name}}; \
    else \
        echo "updating all..."; \
        nix flake update; \
    fi
    git diff flake.lock

remote cmd target:
    ./bin/extra/build-remote-nixos {{target}} {{cmd}}