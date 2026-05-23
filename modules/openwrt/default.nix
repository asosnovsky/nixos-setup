{ pkgs, lib }:

let
  generator = pkgs.rustPlatform.buildRustPackage {
    pname = "openwrt-gen";
    version = "0.1.0";
    src = ./generator;
    cargoLock.lockFile = ./generator/Cargo.lock;
  };
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

    echo "Fetching current config from $SERVER..."
    CURRENT_DNSMASQ=$(ssh "$SERVER" 'cat /etc/dnsmasq.conf' 2>/dev/null || echo "")
    CURRENT_ETHERS=$(ssh "$SERVER" 'cat /etc/ethers' 2>/dev/null || echo "")

    echo ""
    echo "$DNSMASQ"
    echo "=== dnsmasq.conf diff [START] ==="
    comm -3 <(echo "$CURRENT_DNSMASQ" | sort) <(echo "$DNSMASQ" | sort)
    echo "=== dnsmasq.conf diff [END] ==="
    echo ""
    read -p "Looks good? [y/N] " -n 1 -r < /dev/tty; echo
    [[ $REPLY =~ ^[Yy]$ ]] || exit 1

    echo "$ETHERS"
    echo "=== ethers diff [START] ==="
    comm -3 <(echo "$CURRENT_ETHERS" | sort) <(echo "$ETHERS" | sort)
    echo "=== ethers diff [END] ==="
    echo ""

    read -p "Deploy to $SERVER? [y/N] " -n 1 -r < /dev/tty; echo
    [[ $REPLY =~ ^[Yy]$ ]] || exit 1

    echo "$DNSMASQ" | ssh "$SERVER" 'cat > /tmp/dnsmasq.new.conf'
    echo "$ETHERS"  | ssh "$SERVER" 'cat > /etc/ethers'

    ssh "$SERVER" '
      cp /etc/dnsmasq.conf /tmp/dnsmasq.old.conf
      cp /tmp/dnsmasq.new.conf /etc/dnsmasq.conf
      if dnsmasq --test; then
        /etc/init.d/dnsmasq restart
        echo "Done"
      else
        echo "Config invalid, reverting..."
        cp /tmp/dnsmasq.old.conf /etc/dnsmasq.conf
        exit 1
      fi
    '
  '';
in
{
  inherit deployScript;
}
