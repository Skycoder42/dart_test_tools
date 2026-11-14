# Flutter Linux desktop kit for Docker Sandboxes

A declaration-only [Docker Sandboxes](https://docs.docker.com/ai/sandboxes/)
kit (format v3, `kind: mixin`) that adds the native toolchain for
`flutter build linux` on top of the [Flutter SDK kit](../flutter).

- installs `clang cmake ninja-build pkg-config libgtk-3-dev liblzma-dev
  mesa-utils xvfb xauth` with apt in an `install` hook, once per sandbox at create
- opens `deb.debian.org` and `dhi.io` for the install phase only (the
  `claude` workload already allows `deb.debian.org` at runtime)
- `requires: [flutter]`, so it only composes together with the Flutter kit
- agent instructions describing the environment

The kit ships no image layer, so it has nothing to build and works on every
architecture the workload supports. It needs a Debian-based workload with
`apt-get` (the sbx agent workloads are Debian trixie); otherwise the
install hook fails with a clear message.

The sandbox has no display. Run the app or Linux integration tests under
`xvfb-run`, e.g. `xvfb-run -a flutter test integration_test -d linux`.

## Usage

```sh
sbx run claude --kit ./sbx/flutter --kit ./sbx/flutter-linux .
```

Or add `./sbx/flutter-linux` to the `kits` of an `sbxenv.yaml`, as the
repository root does.

## Verify

```sh
sbx kit validate ./sbx/flutter-linux

# inside the sandbox
flutter doctor -v           # "Linux toolchain" must be green
flutter create --platforms linux /tmp/app && cd /tmp/app && flutter build linux
```
