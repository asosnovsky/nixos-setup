#!/usr/bin/env bash
# Bump colibri to a new version.
# Usage: ./update.sh [<version>]
#   With version: bump to that version (e.g. "1.6.0").
#   Without args: auto-detect latest tag from GitHub.
set -euo pipefail

PKG="colibri"
REPO="JustVugg/colibri"

if [ $# -ge 1 ]; then
    VERSION="$1"
else
    echo "Auto-detecting latest colibri version..."
    VERSION=$(curl -fsSL "https://api.github.com/repos/${REPO}/releases" \
        | jq -r '[.[] | select(.tag_name | startswith("v")) | .tag_name | sub("^v"; "")] | .[0]')
    if [ -z "$VERSION" ]; then
        echo "Could not auto-detect latest version from GitHub."
        echo "Usage: $0 [<version>]"
        exit 1
    fi
    echo "Latest: $VERSION"
fi

# Resolve tag to commit hash
REV=$(git ls-remote "https://github.com/${REPO}" "v${VERSION}" | awk '{print $1}')
if [ -z "$REV" ]; then
    echo "Could not find tag v${VERSION} in upstream repo"
    exit 1
fi

sed -i "s/version = \".*\";/version = \"${VERSION}\";/" default.nix
sed -i "s|rev = \".*\";|rev = \"${REV}\";|" default.nix

HASH=$(nix hash file --type sha256 --sri <(curl -fsSL "https://github.com/${REPO}/archive/${REV}.tar.gz"))
sed -i "s|hash = \".*\";|hash = \"${HASH}\";|" default.nix

echo "✅ ${PKG} bumped to ${VERSION} (rev ${REV})"
