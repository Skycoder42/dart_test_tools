# Flutter SDK kit for Docker Sandboxes

A [Docker Sandboxes](https://docs.docker.com/ai/sandboxes/) kit (format v3,
`kind: mixin`) that adds the Flutter and Dart SDK to any agent sandbox.

- SDK at `/opt/flutter`, owned by the `agent` user, on `PATH` together with
  `~/.pub-cache/bin`
- precached for the host (`flutter test`), linux and web targets
- network access for pub.dev, GitHub (git dependencies) and Flutter's
  artifact storage
- Flutter and Dart analytics disabled on every sandbox start
- the [Dart MCP server](https://github.com/dart-lang/ai/tree/main/pkgs/dart_mcp_server)
  (`dart mcp-server`) registered as `dart` in the agent's user config on
  every sandbox start (currently for Claude Code; other agents are skipped)
- the official [Dart](https://github.com/dart-lang/skills) (`dart-*`) and
  [Flutter](https://github.com/flutter/agent-plugins) (`flutter-*`) agent
  skills, exposed in the skills directory of whichever agent the sandbox runs
- optional persistent pub cache volume (`/home/agent/.pub-cache`, 4 GiB)
- agent instructions describing the environment

Platforms: `linux/amd64` and `linux/arm64`. Flutter publishes release
archives for linux-x64 only, so the SDK is checked out from git (like the
[flatpak extension](../../flatpak/flutter-extension)). Flutter's release
index `releases_linux.json` is used to verify that the release tag points to
the published commit and that the Dart version matches.

Not included: tooling for native builds (`flutter build linux` needs
clang/cmake/GTK, `flutter test --platform chrome` needs Chromium, Android
needs a JDK and the Android SDK). iOS and macOS builds are impossible in a
Linux sandbox. The Linux desktop toolchain comes with the
[flutter-linux kit](../flutter-linux), Chromium with the
[flutter-web kit](../flutter-web).

## Usage

```sh
# local source directory (built when the sandbox is created)
sbx run claude --kit ./sbx/flutter .

# published kit
sbx run claude --kit docker.io/skycoder42/sbx-kit-flutter:3.50.0 .
```

Flutter and Gradle builds benefit from more resources than the default, e.g.
`--cpus 4 --memory 8g`.

## Args

| Arg | Phase | Description |
|---|---|---|
| `flutterVersion` | build | Flutter stable release to install |
| `dartVersion` | build | Dart SDK version shipped with that release; the build fails on a mismatch |
| `dartSkillsRef` | build | Commit of `dart-lang/skills` the `dart-*` skills are taken from |
| `flutterSkillsRef` | build | Commit of `flutter/agent-plugins` the `flutter-*` skills are taken from |

All args are build-phase args: they are baked into the published kit. To build
another Flutter version, update `flutterVersion` and `dartVersion` (or pass
`--build-arg`s) together.

Each skill needs its own `agent-skill@1` entry with a literal path, and the
`skills` arg lists the same names: the build fails when they do not match the
skills at the pinned commits. After changing `flutterVersion`, `dartSkillsRef`
or `flutterSkillsRef`, regenerate the derived args from the repository root:

```sh
dart run sbx/tool/update_flutter_skills.dart
```

## Automatic updates

Renovate (see `renovate.json` in the repository root) bumps `flutterVersion`
to the latest stable Flutter release (after 3 days) and `dartSkillsRef` /
`flutterSkillsRef` to the latest `main` commits, as part of the weekly
"all dependencies" pull request. Because the repository `pubspec.yaml` lists
the `regex` manager in `renovate.pre_build_extra_managers`, the post-upgrade
step then runs its `renovate.pre_build_command`, i.e. the tool
above, which sets `dartVersion` and the skill list to match.

## The update tool

The tool looks up the Dart SDK of `flutterVersion` in Flutter's release index
and sets `dartVersion` to it. It fetches both skill repositories at exactly the
pinned commits (it never changes them), lists the `dart-*` skills of `dart-lang/skills` and the
`flutter-*` skills of `flutter/agent-plugins`, and fails if a `SKILL.md`
frontmatter `name` does not match its directory. It then rewrites the `skills`
arg and adds or removes `agent-skill@1` entries in `flutter.yaml`, leaving the
rest of the file untouched, and prints the added and removed skills. If
nothing changed, the file is left as is.

## Build and verify

The descriptor needs the `docker/sandbox-kit:3` BuildKit frontend, i.e.
Docker with Buildx and a `docker-container` builder:

```sh
docker buildx create --name kit-builder --driver docker-container --bootstrap

# validate the descriptor (fails fast) and solve the recipe
docker buildx build --builder kit-builder sbx/flutter -f sbx/flutter/flutter.yaml --output type=cacheonly

# export an OCI layout and run the conformance suite
docker buildx build --builder kit-builder sbx/flutter -f sbx/flutter/flutter.yaml \
  -t sbx-kit-flutter:3.50.0 --output type=oci,dest=/tmp/flutter-layout,tar=false
kit-tck validate --layout /tmp/flutter-layout 3.50.0

# compose it for real
sbx run shell --kit ./sbx/flutter --detached --name flutter-test .
sbx exec flutter-test flutter doctor -v
sbx policy log   # shows blocked hosts
```

## Published images

CI publishes this kit and the [flutter-linux](../flutter-linux) and
[flutter-web](../flutter-web) kits to Docker Hub as
`docker.io/skycoder42/sbx-kit-<kit>` for `linux/amd64` and `linux/arm64`
([`.github/workflows/sbx-kits.yml`](../../.github/workflows/sbx-kits.yml),
called by the repository's CI workflow). A kit is published from `main` whenever
a commit changed it, with three tags:

| Tag | Moves | Use |
|---|---|---|
| `3.50.0-<commit>` | never (immutable) | exactly one build; `<commit>` is the commit it was built from |
| `3.50.0` | with every rebuild of that version (e.g. new skill commits) | a Flutter version, latest build |
| `latest` | with every publish | newest kit |

For exact content, pin the digest (`…@sha256:…`) or use the immutable tag.

Every published kit is checked before any tag points to it: it is built with
SLSA provenance (`mode=max`) and an SPDX SBOM, validated with `kit-tck`,
keyless-signed with `sbx kit sign` and attested with GitHub artifact
attestations. Only then are the tags set, to exactly that digest.

### Verify a published kit

The signer is the kit workflow on `main`, nothing else:

```sh
sbx kit verify docker.io/skycoder42/sbx-kit-flutter:3.50.0 \
  --certificate-identity https://github.com/Skycoder42/dart_test_tools/.github/workflows/sbx-kits.yml@refs/heads/main \
  --certificate-oidc-issuer https://token.actions.githubusercontent.com
```

To make `sbx` refuse unsigned or foreign kits, trust that identity and require
signatures (this replaces the whole `kit.trustedSigners` list):

```sh
sbx settings set kit.trustedSigners '[{"identity":"https://github.com/Skycoder42/dart_test_tools/.github/workflows/sbx-kits.yml@refs/heads/main","issuer":"https://token.actions.githubusercontent.com"}]'
sbx settings set kit.requireSignature true
```

The GitHub-signed build provenance names the repository, workflow, commit and
runner:

```sh
gh attestation verify oci://docker.io/skycoder42/sbx-kit-flutter:3.50.0 \
  --repo Skycoder42/dart_test_tools \
  --signer-workflow Skycoder42/dart_test_tools/.github/workflows/sbx-kits.yml \
  --source-ref refs/heads/main --deny-self-hosted-runners
```

`sbx kit provenance` does not show it: that command only reads the provenance
`sbx kit push` attaches to v1/v2 kits. The BuildKit provenance and SBOM are in
the image index (`docker buildx imagetools inspect <ref> --format '{{json .Provenance}}'`);
they are covered by the signature, because the signed index lists them by
digest.

## Licenses

The image ships the Flutter SDK and the bundled skills unmodified, including
their license files:

- Flutter framework and Dart SDK: BSD-3-Clause (`/opt/flutter/LICENSE`,
  `/opt/flutter/bin/cache/dart-sdk/LICENSE`)
- Flutter engine and its third-party code: see
  `/opt/flutter/bin/cache/pkg/sky_engine/LICENSE` and the `LICENSE.*.md` files
  next to the engine artifacts
- Roboto fonts: Apache-2.0, Material Icons font: CC-BY-4.0
  (`/opt/flutter/bin/cache/artifacts/material_fonts/`)
- `dart-lang/skills` and `flutter/agent-plugins`: BSD-3-Clause
  (`/opt/flutter-skills/LICENSES/`)
- this kit's descriptor and recipe: BSD-3-Clause, see [LICENSE](../../LICENSE)

The descriptor's `licenses` reflect this as
`BSD-3-Clause, Apache-2.0, CC-BY-4.0, LicenseRef-Flutter-Third-Party`.

## Trademarks

Flutter and the related logo are trademarks of Google LLC. This kit is not
endorsed by or affiliated with Google LLC.
