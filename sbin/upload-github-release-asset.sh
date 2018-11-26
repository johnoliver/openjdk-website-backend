#!/usr/bin/env bash
#
# Based On:
# Author: Stefan Buck
# License: MIT
# https://gist.github.com/stefanbuck/ce788fee19ab6eb0b4447a85fc99f447
#
#
#

# Check dependencies.
set -eu
set +x

while getopts "f:t:d:r:v:" opt; do
  case $opt in
    f)
      files+=("$OPTARG")
      ;;
    t)
      tag="$OPTARG"
      ;;
    d)
      description="$OPTARG"
      ;;
    r)
      release="$OPTARG"
      ;;
    v)
      version="$OPTARG"
      ;;
    \?)
      echo "Invalid option: -$OPTARG" >&2
      ;;
  esac
done

# Define variables.
GH_REPO="https://api.github.com/repos/AdoptOpenJDK/open${version}-binaries"
GH_TAGS="$GH_REPO/releases/tags/$tag"
AUTH="Authorization: token $GITHUB_TOKEN"
WGET_ARGS="--content-disposition --auth-no-challenge --no-cookie"
CURL_ARGS="-LJO#"

if [[ "$tag" == 'LATEST' ]]; then
  GH_TAGS="$GH_REPO/releases/latest"
fi

# Validate token.
curl -o /dev/null -sH "$AUTH" $GH_REPO || { echo "Error: Invalid repo, token or network issue!";  exit 1; }

# Read asset tags.
response=$(curl -sH "$AUTH" $GH_TAGS)

# Get ID of the asset based on given filename.
echo "$response"
eval $(echo "$response" | grep -m 1 "id.:" | grep -w id | tr : = | tr -cd '[[:alnum:]]=')
[ "$id" ] || { echo "Error: Failed to get release id for tag: $tag"; echo "$response" | awk 'length($0)<100' >&2; exit 1; }

# Upload asset
echo "Uploading assets... "

for filename in $files;
do
  # Construct url
  GH_ASSET="https://uploads.github.com/repos/AdoptOpenJDK/open${version}-binaries/releases/${id}/assets?name=$(basename $filename)"
  echo "Uploading $filename $GH_ASSET"
  curl "$GITHUB_OAUTH_BASIC" --data-binary @"$filename" -H "$AUTH" -H "Content-Type: application/octet-stream" $GH_ASSET
done