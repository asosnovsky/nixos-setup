#!/usr/bin/env bash
# Interactive deploy entrypoint. Reads router config JSON from stdin — caller
# decrypts the age secret. Usage: age -d secrets/glmain.json.age | openwrt-deploy
#
# Expects these to be exported by the Nix wrapper before this file's content runs:
#   ROUTER        - router IP/hostname
#   ROUTER_USER   - SSH user
#   GENERATOR     - store path of the openwrt-gen package (bin/openwrt-gen inside)
#   APPLY_SCRIPT  - store path of skyg-apply.sh
set -euo pipefail

SERVER="$ROUTER_USER@$ROUTER"

CONFIG=$(cat)

DNSMASQ=$(echo "$CONFIG" | "$GENERATOR"/bin/openwrt-gen dnsmasq)
ETHERS=$(echo "$CONFIG"  | "$GENERATOR"/bin/openwrt-gen ethers)
FIREWALL=$(echo "$CONFIG" | "$GENERATOR"/bin/openwrt-gen firewall)

# Colorized unified diff with a per-file change summary.
# $1 = label, $2 = current (may be empty), $3 = new
show_diff() {
  local label="$1" old="$2" new="$3"
  local oldf newf d
  oldf=$(mktemp) newf=$(mktemp)
  if [ -n "$old" ]; then printf '%s\n' "$old" > "$oldf"; else : > "$oldf"; fi
  if [ -n "$new" ]; then printf '%s\n' "$new" > "$newf"; else : > "$newf"; fi
  echo ""
  echo "=== $label ==="
  if d=$(diff -u "$oldf" "$newf"); then
    echo "  (no changes)"
  else
    printf '%s\n' "$d" | awk '
      /^---/ {printf "\033[2m%s\033[0m\n", $0; next}
      /^\+\+\+/ {printf "\033[2m%s\033[0m\n", $0; next}
      /^@@/  {printf "\033[36m%s\033[0m\n", $0; next}
      /^-/   {printf "\033[31m%s\033[0m\n", $0; next}
      /^\+/  {printf "\033[32m%s\033[0m\n", $0; next}
      {print}
    '
    local added removed
    added=$(printf '%s\n' "$d" | grep -c '^[+][^+]' || true)
    removed=$(printf '%s\n' "$d" | grep -c '^[-][^-]' || true)
    echo "  -> $added added, $removed removed"
  fi
  rm -f "$oldf" "$newf"
}

echo "Fetching current config from $SERVER..."
CURRENT_DNSMASQ=$(ssh "$SERVER" 'cat /etc/dnsmasq.conf' 2>/dev/null || echo "")
CURRENT_ETHERS=$(ssh "$SERVER" 'cat /etc/ethers' 2>/dev/null || echo "")
CURRENT_FIREWALL_ALL=$(ssh "$SERVER" 'uci export firewall' 2>/dev/null || echo "")
# Keep only the skyg-managed rule blocks (for the diff)
CURRENT_FIREWALL=$(echo "$CURRENT_FIREWALL_ALL" | awk '/^config /{if(have && block ~ /skyg_/) print block; block=$0; have=1; next}{if(have) block=block ORS $0}END{if(have && block ~ /skyg_/) print block}')
# Drop the header comment from the generated firewall for a clean diff
NEW_FIREWALL=$(echo "$FIREWALL" | tail -n +2)

show_diff "dnsmasq.conf" "$CURRENT_DNSMASQ" "$DNSMASQ"
show_diff "ethers" "$CURRENT_ETHERS" "$ETHERS"
show_diff "firewall (skyg rules)" "$CURRENT_FIREWALL" "$NEW_FIREWALL"

echo ""
echo "skyg firewall rules to be applied:"
echo "$NEW_FIREWALL" | awk -F"'" '/^config rule/{print "  " $2}'
echo ""

read -p "Deploy to $SERVER? [y/N] " -n 1 -r < /dev/tty; echo
[[ $REPLY =~ ^[Yy]$ ]] || exit 1

TS=$(date +%Y%m%d-%H%M%S)

# Stage the apply script and the new config files on the router
ssh "$SERVER" 'cat > /tmp/skyg_apply.sh' < "$APPLY_SCRIPT"
echo "$DNSMASQ"  | ssh "$SERVER" 'cat > /tmp/dnsmasq.new.conf'
echo "$ETHERS"   | ssh "$SERVER" 'cat > /tmp/ethers.new'
echo "$FIREWALL" | ssh "$SERVER" 'cat > /tmp/skyg_firewall.batch'

# Back up, apply, validate, auto-restore on failure (OpenWrt has no bash, use sh)
ssh "$SERVER" "TS=$TS sh /tmp/skyg_apply.sh"
