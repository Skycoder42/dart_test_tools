#!/usr/bin/env bash
# Prints the published version of a kit: its `version:`, or the default of the
# build arg that `version:` references (`${{ kit.args.<name> }}`).
#
#   sbx/tool/kit-version.sh <kit-directory>
#
# Used by .github/workflows/sbx-kits.yml (the workflow cannot spell the
# reference syntax itself, GitHub Actions would expand it).
set -euo pipefail

kit_dir=${1:?usage: $0 <kit-directory>}
descriptor="$kit_dir/$(basename "$kit_dir").yaml"

version=$(yq -r '.version // ""' "$descriptor")
arg_ref='^\$\{\{ *kit\.args\.([A-Za-z0-9_]+) *\}\}$'
if [[ $version =~ $arg_ref ]]; then
  version=$(ARG="${BASH_REMATCH[1]}" yq -r '.args[strenv(ARG)].default // ""' "$descriptor")
fi

if [[ ! $version =~ ^[0-9]+\.[0-9]+\.[0-9]+$ ]]; then
  echo "$descriptor: cannot resolve a x.y.z version, got '$version'" >&2
  exit 1
fi
echo "$version"
