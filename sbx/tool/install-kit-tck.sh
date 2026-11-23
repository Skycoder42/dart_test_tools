#!/usr/bin/env bash
# Installs the checksum-verified kit-tck into $RUNNER_TEMP and adds it to the
# PATH of the following steps of the GitHub Actions job.
set -euo pipefail

# https://github.com/docker/sandbox-kit-spec/releases
# Both lines are updated together by Renovate (see renovate.json): the tag
# must stay the exact release tag, and the checksum the one of the
# linux_amd64 archive.
KIT_TCK_TAG=v3.0.0-m.13
KIT_TCK_SHA256=9aaf699a662e55c35a2930dd4778a7f4e2317b563d64cc9d21622e6bac6f744c

version=${KIT_TCK_TAG#v}
archive="$RUNNER_TEMP/kit-tck.tar.gz"
curl -fsSL -o "$archive" \
  "https://github.com/docker/sandbox-kit-spec/releases/download/${KIT_TCK_TAG}/kit-tck_${version}_linux_amd64.tar.gz"
echo "$KIT_TCK_SHA256  $archive" | sha256sum -c -
mkdir -p "$RUNNER_TEMP/kit-tck"
tar -xzf "$archive" -C "$RUNNER_TEMP/kit-tck" kit-tck
echo "$RUNNER_TEMP/kit-tck" >> "$GITHUB_PATH"
