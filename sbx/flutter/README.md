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
sbx run claude --kit docker.io/<namespace>/sbx-kit-flutter:3.50.0 .
```

Flutter and Gradle builds benefit from more resources than the default, e.g.
`--cpus 4 --memory 8g`.

## Args

| Arg | Phase | Description |
|---|---|---|
| `flutterVersion` | build | Flutter stable release to install |
| `dartVersion` | build | Dart SDK version shipped with that release; the build fails on a mismatch |

Both are build-phase args: they are baked into the published kit. To build
another version, update both defaults (or pass `--build-arg`s) together.

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

## Publish

```sh
docker buildx build --builder kit-builder sbx/flutter -f sbx/flutter/flutter.yaml \
  --platform linux/amd64,linux/arm64 --provenance=mode=min --push \
  -t docker.io/<namespace>/sbx-kit-flutter:3.50.0 \
  -t docker.io/<namespace>/sbx-kit-flutter:latest
kit-tck validate docker.io/<namespace>/sbx-kit-flutter:3.50.0
```

`sbx` only accepts kits from Docker Hub by default; kits from other
registries need `sbx settings set kit.allowedSources '[...]'`.
