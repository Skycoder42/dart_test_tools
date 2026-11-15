#!/usr/bin/env bash
# Fails unless every platform image of a multi-platform kit carries a SLSA
# provenance and an SPDX SBOM attestation, and the kit has exactly the
# expected number of platform images.
#
#   sbx/tool/check-attestations.sh layout <oci-layout-dir> <platform-count>
#   sbx/tool/check-attestations.sh registry <reference@digest> <platform-count>
#
# Used by .github/workflows/sbx-kits.yml.
set -euo pipefail

mode=${1:?usage: $0 layout|registry <target> <platform-count>}
target=${2:?missing target}
expected=${3:?missing platform count}

case $mode in
  layout)
    blob() { cat "$target/blobs/${1%%:*}/${1#*:}"; }
    index=$(blob "$(jq -r '.manifests[0].digest' "$target/index.json")")
    images=$(jq -r '.manifests[]
      | select(.annotations["vnd.docker.reference.type"] != "attestation-manifest")
      | .digest' <<< "$index")
    count=$(wc -w <<< "$images")
    if [ "$count" -ne "$expected" ]; then
      echo "::error::expected $expected platform images, found $count" >&2
      exit 1
    fi
    for image in $images; do
      attestation=$(jq -r --arg image "$image" '.manifests[]
        | select(.annotations["vnd.docker.reference.type"] == "attestation-manifest"
          and .annotations["vnd.docker.reference.digest"] == $image)
        | .digest' <<< "$index")
      if [ -z "$attestation" ]; then
        echo "::error::$image has no attestation manifest" >&2
        exit 1
      fi
      types=$(blob "$attestation" | jq -r '.layers[].annotations["in-toto.io/predicate-type"] // empty')
      if ! grep -q '^https://slsa.dev/provenance/' <<< "$types"; then
        echo "::error::$image has no SLSA provenance attestation" >&2
        exit 1
      fi
      if ! grep -qx 'https://spdx.dev/Document' <<< "$types"; then
        echo "::error::$image has no SPDX SBOM attestation" >&2
        exit 1
      fi
      echo "$image: $(tr '\n' ' ' <<< "$types")"
    done
    ;;
  registry)
    provenance=$(docker buildx imagetools inspect "$target" --format '{{json .Provenance}}')
    sbom=$(docker buildx imagetools inspect "$target" --format '{{json .SBOM}}')
    # Multi-platform results are keyed by platform.
    jq -e --argjson n "$expected" 'length == $n and all(.[]; .SLSA != null)' \
      <<< "$provenance" > /dev/null || {
      echo "::error::$target lacks SLSA provenance for $expected platforms" >&2
      exit 1
    }
    jq -e --argjson n "$expected" 'length == $n and all(.[]; .SPDX != null)' \
      <<< "$sbom" > /dev/null || {
      echo "::error::$target lacks an SPDX SBOM for $expected platforms" >&2
      exit 1
    }
    echo "$target: provenance and SBOM for $(jq -r 'keys | join(", ")' <<< "$provenance")"
    ;;
  *)
    echo "unknown mode $mode" >&2
    exit 64
    ;;
esac
