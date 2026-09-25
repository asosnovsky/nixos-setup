#!/usr/bin/env bash
# Bump delta to a new version.
# Usage: ./update.sh [<version>]
#   With version: bump to that version.
#   Without args: auto-detect latest nightly from the delta.dev release API.
set -euo pipefail

PKG="delta"
API="https://delta.dev/api/releases/nightly"
ASSET="asset=delta&os=linux&arch=x86_64"

if [ $# -ge 1 ]; then
    VERSION="$1"
else
    echo "Auto-detecting latest ${PKG} version..."
    VERSION=$(curl -fsSL "${API}/latest/asset?${ASSET}" | jq -r .version)
    if [ -z "$VERSION" ] || [ "$VERSION" = "null" ]; then
        echo "Could not auto-detect latest version from delta.dev."
        echo "Usage: $0 [<version>]"
        exit 1
    fi
    echo "Latest: $VERSION"
fi

# The API hands back a short-lived signed URL; resolve it, then hash the file.
URL=$(curl -fsSL "${API}/${VERSION}/asset?${ASSET}" | jq -r .url)

sed -i "s/version = \".*\";/version = \"${VERSION}\";/" default.nix

HASH=$(nix hash file --type sha256 --sri <(curl -fsSL "$URL"))
sed -i "s|outputHash = \".*\";|outputHash = \"${HASH}\";|" default.nix

echo "✅ ${PKG} bumped to ${VERSION}"
