#!/usr/bin/env bash
# Bump buzz-cli to a new version.
# Usage: ./update.sh [<version>]
#   With version: bump to that version.
#   Without args: auto-detect latest from GitHub releases.
# Uses the same desktop-v* tag as buzz-desktop. cargoHash needs a build,
# so it is reset to lib.fakeHash; build once and paste the "got:" hash.
set -euo pipefail

PKG="buzz-cli"
REPO="block/buzz"

if [ $# -ge 1 ]; then
    VERSION="$1"
else
    echo "Auto-detecting latest buzz-cli version..."
    VERSION=$(curl -fsSL "https://api.github.com/repos/${REPO}/releases" \
        | jq -r '[.[] | select(.tag_name | startswith("desktop-v")) | .tag_name | sub("^desktop-v"; "")] | .[0]')
    if [ -z "$VERSION" ] || [ "$VERSION" = "null" ]; then
        echo "Could not auto-detect latest version from GitHub."
        echo "Usage: $0 [<version>]"
        exit 1
    fi
    echo "Latest: $VERSION"
fi

CURRENT=$(sed -n 's/^ *version = "\(.*\)";/\1/p' default.nix | head -n1)
if [ "$CURRENT" = "$VERSION" ]; then
    echo "✅ ${PKG} already at ${VERSION}"
    exit 0
fi

HASH=$(nix flake prefetch "github:${REPO}/desktop-v${VERSION}" --json | jq -r '.hash')
if [ -z "$HASH" ] || [ "$HASH" = "null" ]; then
    echo "Could not prefetch tag desktop-v${VERSION}"
    exit 1
fi

sed -i "s/version = \".*\";/version = \"${VERSION}\";/" default.nix
sed -i "s|hash = .*;|hash = \"${HASH}\";|" default.nix
sed -i "s|cargoHash = .*;|cargoHash = lib.fakeHash;|" default.nix

echo "✅ ${PKG} bumped to ${VERSION}"
echo "   Next: build once, then paste the cargoHash from the \"got:\" line."
