#!/usr/bin/env bash
# Installs the pinned sbx CLI from Docker's apt repository.
set -euo pipefail

# Updated by Renovate (see renovate.json). It lives here and not in the
# workflow, because Renovate runs with the GITHUB_TOKEN, which may not push
# changes to workflow files - such updates would never get a branch.
SBX_VERSION=0.54.0

sudo install -m 0644 sbx/tool/docker-apt.asc /etc/apt/keyrings/docker-sbx.asc
codename=$(. /etc/os-release && echo "$VERSION_CODENAME")
echo "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker-sbx.asc] https://download.docker.com/linux/ubuntu $codename stable" \
  | sudo tee /etc/apt/sources.list.d/docker-sbx.list > /dev/null
sudo apt-get update
sudo apt-get install -y --no-install-recommends "docker-sbx=$SBX_VERSION-*"
sbx version
