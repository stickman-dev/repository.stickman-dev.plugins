#!/usr/bin/env bash
#
# Publish an addon's current version into this Kodi repository.
#
# Usage: ./publish.sh <path-to-addon-source-repo>
#   e.g. ./publish.sh ../service.vpn.manager
#
# What it does:
#   1. Reads the addon id (the source repo's folder name) and version (from its addon.xml).
#   2. Builds a clean zip of the addon's current committed state (git archive) into zips/<id>/.
#   3. Drops loose (unzipped) copies of addon.xml and resources/icon.png next to the zip,
#      since Kodi fetches those directly over HTTP to render the repository browse list
#      before an addon is installed - it doesn't peek inside the zip for that.
#   4. Regenerates zips/addons.xml by pulling addon.xml out of the newest zip for every
#      addon folder under zips/ (so it stays correct even if this repo ends up hosting
#      more than one addon later).
#   5. Regenerates zips/addons.xml.md5.
#   6. Commits and pushes.
#
# Requirements: the addon source repo must be a git repo with no uncommitted changes,
# and its addon.xml version must not already have a zip published here (bump the version
# in addon.xml first).

set -euo pipefail

if [ $# -ne 1 ]; then
    echo "Usage: $0 <path-to-addon-source-repo>" >&2
    exit 1
fi

SOURCE_DIR=$(cd "$1" && pwd)
ADDON_ID=$(basename "$SOURCE_DIR")
REPO_DIR=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)

cd "$SOURCE_DIR"

if [ -n "$(git status --porcelain)" ]; then
    echo "Error: $SOURCE_DIR has uncommitted changes. Commit or stash first." >&2
    exit 1
fi

if [ ! -f addon.xml ]; then
    echo "Error: no addon.xml found in $SOURCE_DIR" >&2
    exit 1
fi

# Grab version="..." from the <addon ...> tag specifically, not the XML prolog's version="1.0"
VERSION=$(grep -m1 '<addon ' addon.xml | grep -oP 'version="\K[0-9][0-9a-zA-Z.]*(?=")')
if [ -z "$VERSION" ]; then
    echo "Error: couldn't find a version in $SOURCE_DIR/addon.xml" >&2
    exit 1
fi

echo "Publishing $ADDON_ID version $VERSION"

ZIP_DIR="$REPO_DIR/zips/$ADDON_ID"
ZIP_NAME="$ADDON_ID-$VERSION.zip"
mkdir -p "$ZIP_DIR"

if [ -f "$ZIP_DIR/$ZIP_NAME" ]; then
    echo "Error: $ZIP_DIR/$ZIP_NAME already exists. Bump the version in addon.xml if you have new changes to publish." >&2
    exit 1
fi

git archive --format=zip --prefix="$ADDON_ID/" -o "$ZIP_DIR/$ZIP_NAME" HEAD
echo "Built $ZIP_DIR/$ZIP_NAME"

cp addon.xml "$ZIP_DIR/addon.xml"
if [ -f resources/icon.png ]; then
    cp resources/icon.png "$ZIP_DIR/icon.png"
fi

# Regenerate addons.xml from the newest zip of every addon this repo hosts
cd "$REPO_DIR"
{
    echo '<?xml version="1.0" encoding="UTF-8" standalone="yes"?>'
    echo '<addons>'
    for dir in zips/*/; do
        addon=$(basename "$dir")
        newest_zip=$(ls "$dir"*.zip | sort -V | tail -n1)
        unzip -p "$newest_zip" "$addon/addon.xml" | tail -n +2
    done
    echo '</addons>'
} > zips/addons.xml

md5sum zips/addons.xml | awk '{print $1}' > zips/addons.xml.md5

git add zips/
git commit -m "Publish $ADDON_ID $VERSION"
git push

echo "Done. Pushed $ADDON_ID $VERSION to $(git remote get-url origin)"
