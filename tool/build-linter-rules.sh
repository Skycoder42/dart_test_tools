#!/bin/bash
set -eo pipefail

TARGET=${1:-lib/analysis_options.yaml}
LINTS_VERSION=$(dart pub deps --json | jq -r '.packages[] | select(.name == "lints") | .version')
LINTS_PATH="${PUB_CACHE:-$HOME/.pub-cache}/hosted/pub.dartlang.org/lints-$LINTS_VERSION/lib/"

KNOWN_LINTS=$(mktemp)
cat "$LINTS_PATH/core.yaml" | yq ".linter.rules.[]"  > $KNOWN_LINTS
cat "$LINTS_PATH/recommended.yaml" | yq ".linter.rules.[]" >> $KNOWN_LINTS
cat "$TARGET" | yq ".linter.rules  | keys | .[]" >> $KNOWN_LINTS

echo "    # NEW LINTS:" >> "$TARGET"
curl -sSL "https://dart-lang.github.io/linter/lints/options/options.html" | \
  grep '[[:space:]]\+- [a-zA-Z0-9_]' | \
  cut -d '-' -f 2 | \
  cut -d ' ' -f 2 | \
  grep -v -f $KNOWN_LINTS | \
  while read line; do echo "    $line: null"; done >> \
  "$TARGET"

