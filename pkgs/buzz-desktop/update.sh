#!/usr/bin/env bash
# Bump buzz-desktop to a new version.
# Usage: ./update.sh [<version>]
#   With version: bump to that version.
#   Without args: auto-detect latest from GitHub releases.
set -euo pipefail

PKG="buzz-desktop"
REPO="block/buzz"
URL_TEMPLATE="https://github.com/block/buzz/releases/download/desktop-v\${VERSION}/Buzz_\${VERSION}_amd64.AppImage"

if [ $# -ge 1 ]; then
    VERSION="$1"
else
    echo "Auto-detecting latest buzz-desktop version..."
    VERSION=$(curl -fsSL "https://api.github.com/repos/${REPO}/releases" \
        | jq -r '[.[] | select(.tag_name | startswith("desktop-v")) | .tag_name | sub("^desktop-v"; "")] | .[0]')
    if [ -z "$VERSION" ]; then
        echo "Could not auto-detect latest version from GitHub."
        echo "Usage: $0 [<version>]"
        exit 1
    fi
    echo "Latest: $VERSION"
fi

URL=$(eval "echo $URL_TEMPLATE")

sed -i "s/version = \".*\";/version = \"${VERSION}\";/" default.nix

HASH=$(nix hash file --type sha256 --sri <(curl -fsSL "$URL"))
sed -i "s|hash = \".*\";|hash = \"${HASH}\";|" default.nix

echo "✅ ${PKG} bumped to ${VERSION}"
