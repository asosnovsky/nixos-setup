#!/usr/bin/env bash
# Probe the network card a host uses for internet traffic.
# Piped to `bash -s` locally or over SSH by `skyg net check` (bin/lib/net.nu).
# Prints KEY=VALUE lines; empty values mean "unknown".
set -u

et() {
  if command -v ethtool >/dev/null 2>&1; then
    ethtool "$@"
  else
    nix-shell -p ethtool --run "ethtool $*"
  fi
}

is_phys() { [ -e "/sys/class/net/$1/device" ]; }

# Interface on the default route (may be a bridge or other virtual device).
iface=$(ip -4 route show default 2>/dev/null | awk '{for (i = 1; i <= NF; i++) if ($i == "dev") { print $(i + 1); exit }}')
nic="$iface"

# Follow a bridge/virtual interface down to a physical port.
if [ -n "$nic" ] && ! is_phys "$nic"; then
  for p in /sys/class/net/"$nic"/brif/* /sys/class/net/"$nic"/lower_*; do
    [ -e "$p" ] || continue
    c=$(basename "$p")
    c=${c#lower_}
    if is_phys "$c"; then nic="$c"; break; fi
  done
fi

# Fallback: first physical interface that is up.
if [ -z "$nic" ] || ! is_phys "$nic"; then
  nic=""
  for d in /sys/class/net/*; do
    n=$(basename "$d")
    if is_phys "$n" && [ "$(cat "$d/operstate" 2>/dev/null)" = "up" ]; then nic="$n"; break; fi
  done
fi

echo "IFACE=$iface"
echo "NIC=$nic"
[ -n "$nic" ] || exit 0

if [ -d "/sys/class/net/$nic/wireless" ] || [ -e "/sys/class/net/$nic/phy80211" ]; then
  echo "TYPE=wifi"
else
  echo "TYPE=ethernet"
fi

echo "DRIVER=$(basename "$(readlink -f "/sys/class/net/$nic/device/driver" 2>/dev/null)" 2>/dev/null)"
echo "LINK=$(cat "/sys/class/net/$nic/speed" 2>/dev/null)"

props=$(udevadm info -q property -p "/sys/class/net/$nic" 2>/dev/null)
echo "VENDOR=$(printf '%s\n' "$props" | sed -n 's/^ID_VENDOR_FROM_DATABASE=//p' | head -1)"
echo "MODEL=$(printf '%s\n' "$props" | sed -n 's/^ID_MODEL_FROM_DATABASE=//p' | head -1)"

# Speeds from ethtool's "Supported link modes" block, e.g. "10 100 1000 2500".
supported=$(et "$nic" 2>/dev/null \
  | awk '/Supported link modes:/ { f = 1; sub(/.*Supported link modes:/, "") }
         /Supported pause frame use:|Supports auto-negotiation:/ { f = 0 }
         f { print }' \
  | grep -oE '[0-9]+base' | grep -oE '^[0-9]+' | sort -n | uniq | tr '\n' ' ')
echo "SUPPORTED=${supported% }"
