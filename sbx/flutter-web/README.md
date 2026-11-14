# Flutter web kit for Docker Sandboxes

A declaration-only [Docker Sandboxes](https://docs.docker.com/ai/sandboxes/)
kit (format v3, `kind: mixin`) that adds a browser for
`flutter test --platform chrome` and web integration tests on top of the
[Flutter SDK kit](../flutter). `flutter build web` already works with the SDK
kit alone.

- installs `chromium chromium-driver fonts-liberation` with apt in an
  `install` hook, once per sandbox at create
- links `/usr/local/bin/google-chrome` to Chromium, the executable name
  Flutter looks for on Linux, unless a `google-chrome` already exists
- opens `deb.debian.org` and `dhi.io` for the install phase only
- `requires: [flutter]`, so it only composes together with the Flutter kit
- agent instructions describing the environment

The kit ships no image layer, so it has nothing to build and works on every
architecture the workload supports. It needs a Debian-based workload with
`apt-get` (the sbx agent workloads are Debian trixie); otherwise the
install hook fails with a clear message.

`CHROME_EXECUTABLE` is deliberately not set: a mixin can only set
environment variables through an image layer, and an `/etc/profile.d` drop
would not reach the agent process. The link does the same job without either.

The sandbox has no display. `flutter test --platform chrome` runs Chromium
headless. Web integration tests use chromedriver:

```sh
chromedriver --port=4444 &
flutter drive --driver test_driver/integration_test.dart \
  --target integration_test/app_test.dart \
  -d web-server --browser-name chrome --headless
```

## Usage

```sh
sbx run claude --kit ./sbx/flutter --kit ./sbx/flutter-web .
```

Or add `./sbx/flutter-web` to the `kits` of an `sbxenv.yaml`, as the
repository root does.

## Verify

```sh
sbx kit validate ./sbx/flutter-web

# inside the sandbox
flutter doctor -v           # "Chrome - develop for the web" must be green
flutter create --platforms web /tmp/app && cd /tmp/app && flutter test --platform chrome
```
