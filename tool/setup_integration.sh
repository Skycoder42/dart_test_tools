#!/usr/bin/env bash
set -euo pipefail

cd "$(dirname "$0")/.."

if [ "${GITHUB_ACTIONS:-}" = true ]; then
	dart run tool/ci_install_flutter.dart
fi

npm ci --prefix tool/renovate --no-audit --no-fund --ignore-scripts
