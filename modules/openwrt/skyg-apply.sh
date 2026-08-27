#!/bin/sh
# Runs ON THE ROUTER (OpenWrt has no bash, this must stay POSIX sh).
# Invoked as:  TS=<timestamp> sh skyg-apply.sh
# Expects the new files staged at /tmp/skyg_firewall.batch, /tmp/dnsmasq.new.conf
# and /tmp/ethers.new. Backs up the configs it overrides, applies the new
# firewall/dnsmasq/ethers, ensures bridge-netfilter sysctls are enabled,
# validates, and auto-restores on failure.
set -euo pipefail
BK=/etc/skyg-backups
mkdir -p "$BK"
cp /etc/config/firewall "$BK/firewall.$TS"
cp /etc/dnsmasq.conf    "$BK/dnsmasq.conf.$TS"
cp /etc/ethers          "$BK/ethers.$TS" 2>/dev/null || true
cp /etc/sysctl.conf     "$BK/sysctl.conf.$TS" 2>/dev/null || true

# --- sysctl: enable bridge netfilter ---
# All of this router's "networks" (apl, cam, lab, ...) are just address
# ranges on one flat L2 bridge (br-lan, single /16 across the whole LAN) --
# there's no real VLAN separation. Without bridge-nf-call-iptables, unicast
# traffic between two hosts on the same bridge is switched at L2 and never
# reaches the FORWARD chain, so the skyg_* DROP rules below silently never
# fire. /etc/sysctl.d/*.conf ships bridge-nf-call-* disabled and is reset on
# firmware upgrades, but /etc/sysctl.conf is applied last and persists.
if ! grep -q '^# BEGIN skyg-managed$' /etc/sysctl.conf 2>/dev/null; then
  {
    echo ''
    echo '# BEGIN skyg-managed'
    echo 'net.bridge.bridge-nf-call-iptables=1'
    echo 'net.bridge.bridge-nf-call-ip6tables=1'
    echo '# END skyg-managed'
  } >> /etc/sysctl.conf
fi
sysctl -e -p /etc/sysctl.conf >/dev/null

# --- Firewall: replace the skyg-managed rules ---
for ref in $(uci show firewall | grep -E '^firewall\.skyg_[^.=]+=' | cut -d= -f1); do
  uci -q del "$ref" || true
done
if ! uci -m import firewall < /tmp/skyg_firewall.batch; then
  echo 'FIREWALL: uci import failed, restoring'
  cp "$BK/firewall.$TS" /etc/config/firewall
  exit 1
fi
if ! uci commit firewall; then
  echo 'FIREWALL: uci commit failed, restoring'
  cp "$BK/firewall.$TS" /etc/config/firewall
  exit 1
fi
/etc/init.d/firewall reload

# --- dnsmasq ---
cp /tmp/dnsmasq.new.conf /etc/dnsmasq.conf
if dnsmasq --test; then
  /etc/init.d/dnsmasq restart
else
  echo 'dnsmasq config invalid, restoring'
  cp "$BK/dnsmasq.conf.$TS" /etc/dnsmasq.conf
  exit 1
fi

# --- ethers ---
cp /tmp/ethers.new /etc/ethers

echo 'Done'
