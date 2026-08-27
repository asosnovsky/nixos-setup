{ pkgs, lib }:

let
  generator = pkgs.rustPlatform.buildRustPackage {
    pname = "openwrt-gen";
    version = "0.1.0";
    src = ./generator;
    cargoLock.lockFile = ./generator/Cargo.lock;
  };

  # Remote apply script: backs up the configs it overrides, applies the new
  # firewall/dnsmasq/ethers, ensures bridge-netfilter sysctls are enabled,
  # validates, and auto-restores on failure. Runs on the router as-is (no Nix
  # templating needed), so it's just referenced directly from disk.
  applyScript = ./skyg-apply.sh;
in
config:

let
  # Config JSON is read from stdin at deploy time — caller decrypts the age secret.
  # Usage: age -d secrets/glmain.json.age | openwrt-deploy
  #
  # The bulk of the logic lives in ./openwrt-deploy.sh; this just exports the
  # Nix-computed values it needs (router address, generator/apply-script store
  # paths) and inlines the file's content after them.
  deployScript = pkgs.writeShellScriptBin "openwrt-deploy" ''
    export ROUTER="${config.router.ip}"
    export ROUTER_USER="${config.router.user}"
    export GENERATOR="${generator}"
    export APPLY_SCRIPT="${applyScript}"
    ${builtins.readFile ./openwrt-deploy.sh}
  '';

  # Dry-run: render the configs locally and write them to .tmp/openwrt-<router>/
  # for review. No SSH, no uci, no router changes. Run from the repo root.
  # The router name is passed as $1 (defaults to glmain) — see ./openwrt-dry-run.sh.
  dryRunScript = pkgs.writeShellScriptBin "openwrt-dry-run" ''
    export GENERATOR="${generator}"
    ${builtins.readFile ./openwrt-dry-run.sh}
  '';
in
{
  inherit deployScript dryRunScript;
}
