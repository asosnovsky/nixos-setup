#!/usr/bin/env bash
# Renders the same three configs locally into .tmp/openwrt-<router>/ for review
# - no SSH, no uci, no router changes. Run from the repo root. Router name is
# passed as $1 (defaults to glmain).
#
# Expects GENERATOR and NIX_DNS_RECORDS to be exported by the Nix wrapper before
# this file's content runs (store paths of the openwrt-gen package and of the
# Nix-generated generalMappings fragment).
set -euo pipefail
if [ $# -ge 1 ]; then ROUTER="$1"; else ROUTER=glmain; fi
OUTDIR=".tmp/openwrt-$ROUTER"
mkdir -p "$OUTDIR"

# Same merge as the real deploy: secret config + Nix-declared skyg.dns records.
CONFIG=$(cat | jq --slurpfile nix "$NIX_DNS_RECORDS" \
  '.generalMappings = ((.generalMappings // []) + $nix[0].generalMappings)')

cp "$NIX_DNS_RECORDS" "$OUTDIR/dns-records.json"

echo "$CONFIG" | "$GENERATOR"/bin/openwrt-gen dnsmasq  > "$OUTDIR/dnsmasq.conf"
echo "$CONFIG" | "$GENERATOR"/bin/openwrt-gen ethers   > "$OUTDIR/ethers"
echo "$CONFIG" | "$GENERATOR"/bin/openwrt-gen firewall > "$OUTDIR/firewall.batch"

echo "Dry-run configs written to $OUTDIR (no router changes made):"
echo "  $OUTDIR/dnsmasq.conf"
echo "  $OUTDIR/ethers"
echo "  $OUTDIR/firewall.batch"
echo "  $OUTDIR/dns-records.json   # Nix-declared skyg.dns records merged in"
