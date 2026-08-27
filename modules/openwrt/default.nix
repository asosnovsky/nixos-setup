{ pkgs, lib }:

let
  generator = pkgs.rustPlatform.buildRustPackage {
    pname = "openwrt-gen";
    version = "0.1.0";
    src = ./generator;
    cargoLock.lockFile = ./generator/Cargo.lock;
  };

  # Remote apply script: backs up the configs it overrides, applies the new
  # firewall/dnsmasq/ethers, validates, and auto-restores on failure.
  # Run on the router as:  TS=<timestamp> bash skyg-apply.sh
  # Expects the new files staged at /tmp/skyg_firewall.batch,
  # /tmp/dnsmasq.new.conf and /tmp/ethers.new.
  applyScript = pkgs.writeText "skyg-apply.sh" ''
    set -euo pipefail
    BK=/etc/skyg-backups
    mkdir -p "$BK"
    cp /etc/config/firewall "$BK/firewall.$TS"
    cp /etc/dnsmasq.conf    "$BK/dnsmasq.conf.$TS"
    cp /etc/ethers          "$BK/ethers.$TS" 2>/dev/null || true

    # --- Firewall: replace the skyg-managed rules ---
    for ref in $(uci show firewall | awk -F. '/\.name=.skyg_/{print $1"."$2}'); do
      uci -q del "$ref" || true
    done
    if ! uci batch < /tmp/skyg_firewall.batch; then
      echo 'FIREWALL: uci batch failed, restoring'
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
  '';
in
config:

let
  # Config JSON is read from stdin at deploy time — caller decrypts the age secret.
  # Usage: age -d secrets/glmain.json.age | openwrt-deploy
  deployScript = pkgs.writeShellScriptBin "openwrt-deploy" ''
    set -euo pipefail
    ROUTER="${config.router.ip}"
    ROUTER_USER="${config.router.user}"
    SERVER="$ROUTER_USER@$ROUTER"

    CONFIG=$(cat)

    DNSMASQ=$(echo "$CONFIG" | ${generator}/bin/openwrt-gen dnsmasq)
    ETHERS=$(echo "$CONFIG"  | ${generator}/bin/openwrt-gen ethers)
    FIREWALL=$(echo "$CONFIG" | ${generator}/bin/openwrt-gen firewall)

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
    echo "$NEW_FIREWALL" | awk -F"'" '/option name/{print "  " $2}'
    echo ""

    read -p "Deploy to $SERVER? [y/N] " -n 1 -r < /dev/tty; echo
    [[ $REPLY =~ ^[Yy]$ ]] || exit 1

    TS=$(date +%Y%m%d-%H%M%S)

    # Stage the apply script and the new config files on the router
    ssh "$SERVER" 'cat > /tmp/skyg_apply.sh' < "${applyScript}"
    echo "$DNSMASQ"  | ssh "$SERVER" 'cat > /tmp/dnsmasq.new.conf'
    echo "$ETHERS"   | ssh "$SERVER" 'cat > /tmp/ethers.new'
    echo "$FIREWALL" | ssh "$SERVER" 'cat > /tmp/skyg_firewall.batch'

    # Back up, apply, validate, auto-restore on failure (OpenWrt has no bash, use sh)
    ssh "$SERVER" "TS=$TS sh /tmp/skyg_apply.sh"
  '';

  # Dry-run: render the configs locally and write them to .tmp/openwrt-<router>/
  # for review. No SSH, no uci, no router changes. Run from the repo root.
  # The router name is passed as $1 (defaults to glmain).
  dryRunScript = pkgs.writeShellScriptBin "openwrt-dry-run" ''
    set -euo pipefail
    if [ $# -ge 1 ]; then ROUTER="$1"; else ROUTER=glmain; fi
    OUTDIR=".tmp/openwrt-$ROUTER"
    mkdir -p "$OUTDIR"

    CONFIG=$(cat)

    echo "$CONFIG" | ${generator}/bin/openwrt-gen dnsmasq  > "$OUTDIR/dnsmasq.conf"
    echo "$CONFIG" | ${generator}/bin/openwrt-gen ethers   > "$OUTDIR/ethers"
    echo "$CONFIG" | ${generator}/bin/openwrt-gen firewall > "$OUTDIR/firewall.batch"

    echo "Dry-run configs written to $OUTDIR (no router changes made):"
    echo "  $OUTDIR/dnsmasq.conf"
    echo "  $OUTDIR/ethers"
    echo "  $OUTDIR/firewall.batch"
  '';
in
{
  inherit deployScript dryRunScript;
}
