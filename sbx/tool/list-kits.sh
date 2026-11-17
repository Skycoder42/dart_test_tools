#!/usr/bin/env bash
# Prints all kits (sbx/<kit>/<kit>.yaml) with their published version as JSON
# list of {kit, version} objects, for use as a GitHub Actions matrix.
set -euo pipefail

kits='[]'
for dir in sbx/*/; do
  kit=$(basename "$dir")
  [ -f "$dir/$kit.yaml" ] || continue
  version=$(sbx/tool/kit-version.sh "sbx/$kit")
  echo "$kit: $version" >&2
  kits=$(jq -c --arg kit "$kit" --arg version "$version" \
    '. + [{kit: $kit, version: $version}]' <<< "$kits")
done
echo "$kits"
