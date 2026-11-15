# Plan: Flutter-Kit für Docker Sandboxes (sbx, Kit-Format v3)

Stand: 2026-11-13 · lokale `sbx`-Version: v0.53.0 · Spezifikation: `docker/sandbox-kit-spec` (`SPEC-v3.md`, experimentell, final geplant Q4 2026)

> Legende: **⚠️ verifizieren** = plausibel, aber nicht durch die Spezifikation oder einen Test belegt. Diese Punkte klärt der Spike in Phase 0.

---

## 1. Was ein „SBX v3 Kit“ ist

Ein Kit ist ein **ganz normales OCI-Image**. Der **Descriptor** hängt als Manifest-Annotation `vnd.docker.sandbox.kit.descriptor` daran, der Inhalt liegt in den Layern. Gebaut wird mit einem BuildKit-Frontend, das die erste Zeile des Descriptors auswählt:

```yaml
# syntax=docker/sandbox-kit:3
```

| Kind | Inhalt | Pro Komposition |
|---|---|---|
| `workload` | vollständiges Root-FS. Entrypoint, Env, User und Workdir kommen aus der Image-Config. | genau 1 (z. B. das Agent-Image `claude`, `codex`, `shell`) |
| `mixin` | Overlay auf das Workload-FS, auch rein deklarativ ohne Layer möglich | 0..n |
| `set` | nur beim Authoring: listet veröffentlichte Kits per `kits:` auf. Beim Publish entsteht daraus ein `workload` oder `mixin`. | – |

Was ein Kit vom Host braucht, fordert es über eine typisierte Liste `capabilities` an. Für uns relevant:

| Capability | Wofür bei Flutter |
|---|---|
| `network-policy@1` / `@2` | Egress-Allow-List **pro Phase** (`install` / `runtime`). Eine fehlende Phase gibt nichts frei. `@2` kann zusätzlich nach Methode und Pfad einschränken. |
| `lifecycle@1` | `install`-Hooks (einmal beim Create), `startup`-Hooks (bei jedem Boot, müssen idempotent sein), `files`. Hook-Env ist **deny-by-default**: Variablen wie `HTTPS_PROXY` müssen explizit in `env:` stehen. |
| `volume@1` | persistenter Pub-Cache, pro Sandbox |
| `host-mount@1` | Cache, den mehrere Sandboxes und der Host teilen (z. B. Pub-Cache) |
| `resources@1` | Default-CPU und -RAM. Flutter-Builds brauchen deutlich mehr als der Standard. Wirkt nur am Workload, an Mixins wird es ignoriert. |
| `agent-context@1`/`@2` | Anweisungen für den Agenten („nutze `flutter test`, `dart analyze` …“) |
| `agent-skill@1` | Skills mitliefern, z. B. die beiden Skills aus diesem Repo |

Weitere Regeln, die das Design bestimmen:

- **Plattform-Floor** jedes Workloads: `bash`, `sh`, `curl`, `git`, CA-Store, User `agent` (uid 1000, Home `/home/agent`). Mehr darf ein Mixin nicht voraussetzen.
- **apt-Pakete passen nicht in ein Mixin-Overlay**: Sie brauchen die dpkg-Datenbank und die Shared-Library-Closure der Basis. Ein Mixin kann sie nur per `install`-Hook nachinstallieren. Wer sie fest im Image will, braucht einen eigenen Workload.
- **Ownership im Overlay**: `/home` muss root gehören, `/home/agent` uid 1000. Am besten fasst das Overlay `/home` gar nicht an und installiert nach `/opt` bzw. `/usr/local`.
- **ENV im Mixin** wird gemergt, `PATH` wird angehängt. Jeder andere Key gehört dem ersten Kit, das ihn setzt. Setzt ein zweites Kit denselben Key auf einen anderen Wert, schlägt die Komposition fehl.
- **`provides` muss beim Publish versioniert sein** (z. B. `flutter@3.38.1`). Der Build sollte die installierte Version prüfen.
- **`requires` ist ein Closed-Set-Check**: niemals den Plattform-Floor (`deb/curl`) oder optionale Dinge fordern.
- Nutzung: `sbx run claude --kit <ref>`. Als `<ref>` gehen ein lokales Verzeichnis, `git+https://…#dir=…` oder ein OCI-Ref. `kit.allowedSources` erlaubt **standardmäßig nur Docker Hub**. Ein Kit auf ghcr.io muss also freigeschaltet werden: `sbx settings set kit.allowedSources '[…]'`.
- v3 braucht `sbx` ≥ 0.45. v1/v2-Kits lassen sich nicht mit v3 kombinieren.

Quellen: <https://docs.docker.com/ai/sandboxes/customize/>, `…/customize/author/`, `…/customize/use-kits/`, <https://github.com/docker/sandbox-kit-spec> (`docs/spec/SPEC-v3.md`, `docs/spec/capabilities/…`, `skills/create-kit-v3/{SKILL,RECIPES}.md`, Beispiele `gh`, `dev-tools`, `shell`, `optional-cache`, `shared-cache`).

---

## 2. Was Flutter in einer Sandbox braucht

| Bereich | Bedarf | Konsequenz fürs Kit |
|---|---|---|
| Flutter SDK | Git-Checkout bzw. Release-Archiv (`storage.googleapis.com/flutter_infra_release/releases/stable/linux/flutter_linux_<v>-stable.tar.xz`). `bin/cache` muss **schreibbar** sein, denn Flutter lädt dort Artefakte nach und aktualisiert sie. | SDK nach `/opt/flutter`, `chown -R 1000:1000`. Das vermeidet auch das Git-Problem „dubious ownership“, ohne `/etc/gitconfig` zu überschreiben, was mit dem Base-File kollidieren würde. Beim Build `flutter precache` für die gewünschten Targets. |
| Architektur | **Bestätigt:** `releases_linux.json` (`storage.googleapis.com/flutter_infra_release/releases/releases_linux.json`) listet nur x64-Archive. | **Entschieden** (wie `flatpak/flutter-extension`): Für beide Architekturen Git-Checkout des Release-Tags plus `precache`. Die JSON dient als Versionsautorität: Commit-Hash des Tags und Dart-Version werden geprüft. Umgesetzt in [`sbx/flutter/`](../sbx/flutter/). |
| Dart | im SDK enthalten (`/opt/flutter/bin/dart`) | `provides: [flutter@X, dart@Y]`. Der Build liest Y aus `flutter --version --machine`. |
| Pub | `PUB_CACHE`, Netzwerk zu pub.dev und dem Archiv-Storage | `ENV PUB_CACHE=/home/agent/.pub-cache`, dazu ein optionales `volume@1` oder `host-mount@1` |
| Analytics und Telemetrie | sollen in der Sandbox nicht nach Hause telefonieren | `startup`-Hook (idempotent): `flutter config --no-analytics --no-cli-animations; dart --disable-analytics` |
| Linux-Desktop-Target | apt: `clang cmake ninja-build pkg-config libgtk-3-dev liblzma-dev libstdc++-12-dev` | Kein Overlay möglich, daher entweder `install`-Hook mit apt (install-Phase-Egress zu `deb.debian.org`) oder ein eigener Workload |
| Web-Target / `flutter test --platform chrome` | Chrome/Chromium plus `CHROME_EXECUTABLE` | Chromium per apt, also wie Linux-Desktop. `ENV CHROME_EXECUTABLE` kann kollidieren ⚠️, ggf. per Profil setzen. |
| iOS/macOS | nicht möglich (Linux-microVM) | explizit out of scope, im Agent-Context erwähnen |
| Ressourcen | Flutter-Builds brauchen ≥ 4 CPU und ≥ 8 GB RAM | `resources@1` nur im eigenen Workload oder Set, sonst `--cpus/--memory` dokumentieren |

### 2.1 Netzwerk-Allow-List (Startpunkt, im Spike mit `sbx policy log` verfeinern)

| Zweck | Hosts | Phase |
|---|---|---|
| Flutter-SDK-Artefakte, Engine-Maven | `storage.googleapis.com` (Pfade `/flutter_infra_release/**`, `/download.flutter.io/**`) | runtime (+ install, falls ein Hook `precache` ausführt) |
| Pub | `pub.dev`, `pub.dartlang.org` (Legacy-Redirect), Archiv-Downloads auf `storage.googleapis.com` ⚠️ Pfad verifizieren | runtime |
| Git-Dependencies | `github.com`, `codeload.github.com`, `objects.githubusercontent.com` | runtime |
| `google_fonts` in Golden-Tests | `fonts.googleapis.com`, `fonts.gstatic.com` | runtime, `optional` |
| apt (Linux/Web per Hook) | `deb.debian.org` (+ `dhi.io` bei DHI-Basis) | install |

`storage.googleapis.com` ist ein sehr breiter Host, über den jeder GCS-Bucket erreichbar ist. Deshalb `network-policy@2` mit Pfad-Bounds, sofern die Laufzeit Pfade bei TLS-Verbindungen durchsetzt. Das erwähnt das `gh`-Beispiel für github.com.

### 2.2 Proxy und TLS: größtes technisches Risiko ⚠️

Laut Docs nutzen Agenten „einen Forward-Proxy für HTTP und HTTPS, anderer TCP-Traffic wird transparent weitergeleitet“. Der Proxy injiziert Header, terminiert TLS also. Unklar ist:

- **Dart** (`pub get`, `flutter`): Dart liest `http_proxy`/`https_proxy` und vertraut auf Linux dem System-CA-Store. Sollte funktionieren. Im Spike prüfen.

---

## 3. Zielarchitektur

Wir bauen **Mixins auf den offiziellen Agent-Workloads**. Flutter ist ein Werkzeug, das zu einem Agenten hinzukommt. Agent-Updates (Claude, Codex …) bleiben so unabhängig von uns, und jeder Agent funktioniert.

```text
sbx run claude \
  --kit docker.io/skycoder42/sbx-kit-flutter:3.38.1
```

| Kit | Kind | Inhalt | Plattformen |
|---|---|---|---|
| `sbx-kit-flutter` | mixin | Flutter-SDK unter `/opt/flutter` (precached für linux/web), ENV, Netzwerk für pub/flutter/git, Analytics-off-Hook, Agent-Context, optionaler Pub-Cache (Group: Volume + Datei) | amd64, arm64 |
| `sbx-kit-flutter-linux` | mixin, deklarativ (kein Layer) | `install`-Hook mit apt (`clang cmake ninja-build pkg-config libgtk-3-dev …`) und install-Egress `deb.debian.org`. Der Hook prüft auf `apt-get` und bricht mit klarer Meldung ab, ohne `requires: deb/apt`. | alle |
| `sbx-kit-flutter-web` | mixin, deklarativ | `install`-Hook mit apt `chromium`, `CHROME_EXECUTABLE` per `/etc/profile.d` oder Startup-Datei | alle |
| `sbx-kit-claude-flutter` (optional) | set | `claude` + `flutter` als **eine** Referenz, mit `resources@1` (4 CPU / 8g) | wie Inhalt |

**Alternative B, falls Phase 0 zeigt, dass apt-Hooks zu langsam oder unzuverlässig sind:** ein eigener `flutter`-**Workload** auf `dhi.io/sbx-templates:shell-docker` mit allen apt-Abhängigkeiten im Image, dazu ein Agent-**Mixin** (z. B. `claude-mixin`). Nachteil: Wir müssen die Basis selbst pflegen.

### 3.1 Repo-Layout (Vorschlag: in `dart_test_tools`)

```text
sbx/
  flutter/
    flutter.yaml          # Descriptor
    flutter.dockerfile    # Content-Recipe (Companion-Pair via Dateinamen-Stem)
    README.md
  flutter-linux/    (yaml)              # declaration-only
  flutter-web/      (yaml)              # declaration-only
  claude-flutter/   (yaml, kind: set)
```

Der CI-Workflow ist **nicht** generiert: [`.github/workflows/sbx-kits.yml`](../.github/workflows/sbx-kits.yml) ist handgeschrieben und nur für dieses Repo gedacht (siehe Phase 3).

### 3.2 Entwurf `sbx/flutter/flutter.yaml` (nicht validiert)

```yaml
# syntax=docker/sandbox-kit:3
# yaml-language-server: $schema=https://raw.githubusercontent.com/docker/sandbox-kit-spec/main/schema/kit.schema.json
schemaVersion: "3"
kind: mixin
displayName: Flutter SDK
author: "Skycoder42"
description: Flutter and Dart SDK under /opt/flutter, precached for linux and web
sourceUrl: https://github.com/Skycoder42/dart_test_tools
licenses: [BSD-3-Clause]
version: "${{ kit.args.flutterVersion }}"

args:
  flutterVersion:
    default: "3.38.1"            # Platzhalter – aktuelle stable einsetzen; renovate: datasource=flutter-version
    pattern: '^[0-9]+\.[0-9]+\.[0-9]+$'
    description: Flutter stable release to install
    buildArg: FLUTTER_VERSION
  dartVersion:                   # in der Recipe gegen `dart --version` geprüft
    default: "3.10.0"
    pattern: '^[0-9]+\.[0-9]+\.[0-9]+$'
    buildArg: DART_VERSION

provides:
  - "flutter@${{ kit.args.flutterVersion }}"
  - "dart@${{ kit.args.dartVersion }}"

capabilities:
  - type: com.docker.sandbox/network-policy@2
    config:
      runtime:
        allow:
          - pub.dev
          - pub.dartlang.org
          - hosts: [storage.googleapis.com]
            methods: [GET, HEAD]
            paths: [/flutter_infra_release/**, /download.flutter.io/**, /pub-packages/**]
          - github.com
          - codeload.github.com
          - objects.githubusercontent.com

  - type: com.docker.sandbox/lifecycle@1
    config:
      startup:
        - description: Disable Flutter/Dart analytics (idempotent)
          command: [sh, -c, "flutter config --no-analytics --no-cli-animations >/dev/null; dart --disable-analytics >/dev/null"]
          env: [PUB_CACHE, FLUTTER_ROOT, HTTPS_PROXY, HTTP_PROXY, NO_PROXY]

  - group:
      name: Persistent pub cache
      optional: true
      capabilities:
        - type: com.docker.sandbox/volume@1
          config: {path: /home/agent/.pub-cache, size: 4g}

  - type: com.docker.sandbox/agent-context@2
    optional: true
    config:
      content: |
        ## Flutter ${{ kit.args.flutterVersion }}
        - `flutter` and `dart` are on PATH (/opt/flutter). Do not run `flutter upgrade`/`channel`.
        - Use `dart analyze`, `dart format`, `flutter test`. `flutter build linux|web` need the
          flutter-linux / flutter-web kits; iOS/macOS builds are impossible in this sandbox.
        - Network is allow-listed. If pub fails with 403, report the host, don't work around it.
```

Den Kontext zusätzlich als `agent-context@1` (beide `optional`, mit YAML-Anker) zu deklarieren, wie in den Beispielen, entscheidet die Laufzeit-Policy. Für `sbx` ≥ 0.53 reicht vermutlich `@2` ⚠️.

### 3.3 Entwurf `sbx/flutter/flutter.dockerfile` (nicht validiert)

```dockerfile
# syntax=docker/dockerfile:1
FROM dhi.io/debian-base:trixie-dev AS build
ARG TARGETARCH FLUTTER_VERSION DART_VERSION
RUN apt-get update && apt-get install -y --no-install-recommends ca-certificates curl git xz-utils unzip \
 && rm -rf /var/lib/apt/lists/*
RUN set -eux; mkdir -p /out/opt; \
    if [ "$TARGETARCH" = amd64 ]; then \
      curl -fsSL "https://storage.googleapis.com/flutter_infra_release/releases/stable/linux/flutter_linux_${FLUTTER_VERSION}-stable.tar.xz" \
        | tar -xJ -C /out/opt; \
    else \
      git clone --depth 1 -b "${FLUTTER_VERSION}" https://github.com/flutter/flutter.git /out/opt/flutter; \
    fi; \
    export PATH=/out/opt/flutter/bin:$PATH FLUTTER_ROOT=/out/opt/flutter; \
    flutter config --no-analytics; \
    flutter precache --linux --web --no-android --no-ios --no-macos --no-windows --no-fuchsia; \
    flutter --version | grep -q "Flutter ${FLUTTER_VERSION} "; \
    dart --version 2>&1 | grep -q "${DART_VERSION}"; \
    chown -R 1000:1000 /out/opt/flutter
# ⚠️ verifizieren: Bleiben absolute Pfade in bin/cache (Snapshots, Stamps) nach dem
#    Umzug /out/opt/flutter → /opt/flutter gültig? Sonst im Build-Stage direkt nach
#    /opt/flutter installieren und nur diesen Pfad kopieren.

FROM scratch
COPY --from=build /out /
ENV FLUTTER_ROOT=/opt/flutter \
    PUB_CACHE=/home/agent/.pub-cache \
    PATH=/opt/flutter/bin:/home/agent/.pub-cache/bin
```

---

## 4. Phasen

### Phase 0: Spike (≈ 1–2 Tage)
1. `sbx login`, `sbx run shell` und darin Flutter von Hand installieren.
2. `sbx policy log` mitlaufen lassen bei `flutter precache`, `flutter create`, `flutter pub get`, `flutter test`, `flutter build web`. So entsteht die echte Allow-List.
3. Proxy und TLS klären (Abschnitt 2.2): Wie sind `HTTPS_PROXY` und CA in der Sandbox gesetzt?
4. Auf einem arm64-Host prüfen, ob Flutter per Git-Tag läuft und ob Release-Archive für arm64 existieren.
5. Prüfen, ob die Laufzeit `network-policy@2`-Pfad-Bounds auf `storage.googleapis.com` durchsetzt.
6. Prüfen, ob `/opt/flutter` nach dem Verschieben aus dem Build-Stage noch funktioniert (siehe ⚠️ oben).

**Abnahme:** dokumentierte Host-Liste, Entscheidung zwischen Mixin-Ansatz und Alternative B, bekannte Proxy-Workarounds.

### Phase 1: `sbx-kit-flutter` (Kern)

> **Stand 2026-11-13:** umgesetzt in [`sbx/flutter/`](../sbx/flutter/) (Flutter 3.50.0 / Dart 3.14.0). Das Recipe wurde mit Podman für amd64 gebaut (Overlay 1,8 GB). Auf einer Basis mit Plattform-Floor laufen als uid 1000 `flutter doctor`, `create`, `pub get`, `dart analyze`, `flutter test` und `build web` erfolgreich, das Ownership-Audit ist sauber. **Offen:** Build über das `docker/sandbox-kit:3`-Frontend (Descriptor-Validierung, `kit-tck`), arm64, echter `sbx run` mit Netzwerk-Policy.

- Descriptor und Recipe wie in 3.2/3.3. Lokal: `docker buildx create --name kit-builder --driver docker-container --bootstrap`.
- Prüfen:
  - Validierung: `docker buildx build --builder kit-builder sbx/flutter -f sbx/flutter/flutter.yaml --output type=cacheonly`
  - OCI-Layout exportieren, dann `kit-tck validate --layout … <version>`
  - Ownership-Audit (awk-Pipeline aus `RECIPES.md`)
  - echte Komposition: `sbx run claude --kit ./sbx/flutter --detached --name t . && sbx exec t flutter doctor -v && sbx exec t flutter test`
- **Abnahme:** `flutter create` + `pub get` + `test` + `build web` laufen in `claude`- und `shell`-Sandboxes auf amd64 und arm64.

### Phase 2: `sbx-kit-flutter-linux` und `-web`
- Deklarative Mixins mit apt-`install`-Hooks
- **Abnahme:** `flutter build linux` und `flutter test --platform chrome` funktionieren auf dem `shell`- und dem `claude`-Workload (beide Debian-basiert ⚠️ prüfen).

### Phase 3: Distribution und CI

> **Stand 2026-11-14:** umgesetzt, aber **noch nie in CI gelaufen**. Die mit ⚠️ markierten Punkte zeigt erst der erste Lauf. Alle Prüfungen schlagen dann fehl, statt still schwächer zu werden.

#### P3.1 Entscheidungen

| # | Frage | Entscheidung |
|---|---|---|
| E1 | Login bei Docker Hub | **Benutzername und Token** im GitHub-Environment `docker-hub`, Secrets `dockerHubUsername` und `dockerHubToken` (dieselben Namen wie in den Reusable Workflows). OIDC-Login (ohne gespeichertes Secret) gibt es bei Docker Hub nur für **Organisationen** mit Team-, DSOS- oder Business-Plan ([Docs](https://docs.docker.com/security/authentication/oidc-connections/)). Der Account ist ein privater Plan. Folge: siehe R1. |
| E2 | Form des Workflows | **Repo-lokaler Reusable Workflow** [`sbx-kits.yml`](../.github/workflows/sbx-kits.yml), handgeschrieben (nicht über `tool/ci_gen`), aufgerufen aus `dart_test_tools_ci.yml` als `uses: ./.github/workflows/sbx-kits.yml`. Offizielle Docker-Actions, wo möglich. |
| E3 | Tags | Beweglich: `<version>` und `latest`. Fest: `<version>-<commit-sha>`, wird in Docker Hub später unveränderlich gestellt. Erzeugt mit `docker/metadata-action`. |
| E4 | Lizenzen und Marke | `licenses:` korrigiert, Marken-Hinweis in Descriptoren und READMEs (siehe P3.2). |

Warum ein Reusable Workflow (E2) und kein eigenständiger `on: push`-Workflow:

- Renovate-PRs merged `renovate-finish` mit dem `GITHUB_TOKEN`. Pushes mit diesem Token lösen **keine** `on: push`-Workflows aus. Ein eigenständiger Workflow würde nach dem wöchentlichen Merge nie laufen. Der CI-Workflow wird nach dem Merge dagegen per `workflow_dispatch` neu gestartet und nimmt den Kit-Job mit.
- `renovate-finish` wertet nur die `needs` des CI-Workflows aus. Der Job `sbx-kits` steht jetzt dort, ein kaputtes Kit blockiert also den Auto-Merge.
- Signatur und GitHub-Attestation tragen den `job_workflow_ref` des Reusable Workflows. Der Signierer ist damit genau `sbx-kits.yml@refs/heads/main`, isoliert vom Aufrufer (SLSA Build L3). Ein eigenständiger Workflow käme nur auf L2.

Zu E3 (entschieden): `<commit-sha>` ist `github.sha`, also der Commit, auf dessen Stand gebaut wurde. Er stimmt mit Provenance und Attestation überein.
- Der CI-Workflow läuft bei jedem Push auf `main`. Damit nicht jeder Commit alle drei Kits neu baut (QEMU-Build von Flutter dauert lange), trägt der Index jedes Kits die Annotation `org.opencontainers.image.revision=<github.sha>`.
- Der Job `changes` liest sie vom aktuellen `<version>`-Tag und vergleicht diesen Commit per `git diff` mit `HEAD` (nur `sbx/<kit>` und `sbx-kits.yml`). Kein Unterschied: Das Kit wird übersprungen. Fehlt der Tag, die Annotation oder der Commit: Das Kit wird gebaut.
- Schlägt ein Publish fehl, bleibt der Tag stehen, und der nächste Lauf holt ihn nach. Das ist selbstheilend.
- Wie bisher gilt: Die Prüfung braucht öffentliche Repos auf Docker Hub (ohne Login). Solange sie privat sind, wird bei jedem Lauf neu gebaut.

#### P3.2 Befunde: Lizenzen und Marke

Das Image enthält `/opt/flutter` (Git-Checkout plus Precache) und `/opt/flutter-skills`. Alle Bestandteile bringen ihre Lizenztexte selbst mit:

| Teil | Lizenz | Hinweis im Image |
|---|---|---|
| Flutter-Framework | BSD-3-Clause | `/opt/flutter/LICENSE` |
| Dart SDK | BSD-3-Clause | `bin/cache/dart-sdk/LICENSE` |
| Engine und Drittcode (Skia, ICU, HarfBuzz, BoringSSL, zlib …) | viele | `bin/cache/pkg/sky_engine/LICENSE` (rund 1.700 Abschnitte) und `LICENSE.*.md` neben den Artefakten |
| Roboto-Fonts | Apache-2.0 | `artifacts/material_fonts/*_LICENSE.txt` |
| Material-Icons-Font | **CC-BY-4.0** | ebenda |
| `dart-lang/skills`, `flutter/agent-plugins` | BSD-3-Clause | `/opt/flutter-skills/LICENSES/` |
| Descriptor und Recipe (vom Frontend mit abgelegt) | BSD-3-Clause (dieses Repo) | – |

- **Keine zusätzlichen Lizenzen nötig.** BSD, MIT, Apache und CC-BY verlangen beim Weitergeben, dass die Hinweise erhalten bleiben. Das ist erfüllt, weil das SDK vollständig kopiert wird. **Beim Verkleinern des Images dürfen keine `LICENSE*`-Dateien gelöscht werden.**
- **`licenses:` war zu eng.** Laut Spezifikation (SPEC-v3 §9.5) beschreibt das Feld den gesamten ausgelieferten Inhalt, und daraus entsteht die Annotation `org.opencontainers.image.licenses`. Jetzt steht dort `[BSD-3-Clause, Apache-2.0, CC-BY-4.0, LicenseRef-Flutter-Third-Party]`. Der `LicenseRef-` ist gültiges SPDX und verweist auf die Hinweisdatei der Engine. Die beiden deklarativen Kits liefern nur den Descriptor aus und bleiben bei `BSD-3-Clause`.
- **Marke:** Die [Flutter-Markenrichtlinien](https://docs.flutter.dev/brand) verbieten „Flutter“ in eigenen Produktnamen ohne schriftliche Erlaubnis und verlangen den Hinweis: „Flutter and the related logo are trademarks of Google LLC. We are not endorsed by or affiliated with Google LLC.“ Beschreibende Namen („Flutter SDK“, `sbx-kit-flutter`, vergleichbar mit `org.freedesktop.Sdk.Extension.flutter` auf Flathub) halte ich für vertretbar. Das ist eine Einschätzung, keine Rechtsberatung. Der Hinweis steht jetzt in allen drei `description`s und in den READMEs. Er gehört auch in die Beschreibungen der Repositories auf Docker Hub (von Hand).

#### P3.3 Befunde: offizielles Tooling

- **Bauen und pushen:** Für v3 ist `docker buildx build -f <kit>.yaml … --push` der offizielle Weg ([Docs](https://docs.docker.com/ai/sandboxes/customize/author/distribute/)). `sbx kit pack`, `push` und `pull` sind nur für v1/v2. Der Workflow nutzt `docker/build-push-action` mit dem Descriptor als `file:`.
- **Plattformen:** Ein Aufruf mit QEMU für `linux/amd64,linux/arm64`, wie im eigenen [Release-Workflow](https://github.com/docker/sandbox-kit-spec/blob/main/.github/workflows/release.yaml) der Spezifikation. Native arm64-Runner mit anschließendem `imagetools create` würden die Index-Annotationen des Kits verlieren (SPEC-v3 §9.3).
- **Signieren:** `sbx kit sign <ref>`, keyless über Fulcio und Rekor. Das OIDC-Token von GitHub Actions wird automatisch erkannt. Prüfen: `sbx kit verify --certificate-identity … --certificate-oidc-issuer …`. Erzwingen: `kit.trustedSigners` plus `kit.requireSignature` ([Docs](https://docs.docker.com/ai/sandboxes/customize/use-kits/)).
- **Provenance:** `sbx kit provenance` liest nur die Provenance, die `sbx kit push` an v1/v2-Kits hängt. An Dockers eigenem Kit `docker.io/sbx/neovim` meldet es „no provenance attached“, obwohl der Index BuildKit-Attestations enthält. Docker signiert die eigenen Kits nicht. Für `sbx kit sign` an v3-Images gibt es also kein Vorbild.
- **Frontend und Attestations:** Das Frontend reicht `attest:*` nicht an den Dockerfile-Sub-Solve weiter. BuildKit erzeugt die Attestations auf oberster Ebene, `--provenance` funktioniert also. ⚠️ Ob `--sbom` mit diesem Custom-Frontend funktioniert, ist nicht belegt. CI prüft beides und schlägt sonst fehl.
- **Digest-Pins:** Eine `# syntax=docker/sandbox-kit:3@sha256:…`-Zeile wird akzeptiert. Geprüft mit `sbx kit validate ./sbx/flutter-web` über den Kit-Builder. Das Frontend lehnt nur ein Recipe ab, das selbst das Kit-Frontend nennt.
- **`sbx` in CI:** Paket `docker-sbx` aus Dockers GPG-signiertem apt-Repository (Ubuntu 24.04). Dort liegt aktuell höchstens **0.51.0**. Die neueren `.deb`s auf [GitHub](https://github.com/docker/sbx-releases/releases) sind unsigniert und nicht attestiert, nur eine unsignierte BuildKit-Provenance-JSON liegt dabei. `sbx kit sign` gibt es seit spätestens 0.51. Gewählt: apt mit Versions-Pin und geprüftem Fingerprint des Docker-Schlüssels.
- **kit-tck:** GitHub-Release mit `checksums.txt` (aktuell nur Pre-Releases, `v3.0.0-m.12`). Version und SHA-256 sind im Workflow gepinnt.

#### P3.4 Umsetzung

Neu oder geändert:

- [`.github/workflows/sbx-kits.yml`](../.github/workflows/sbx-kits.yml): Jobs `changes` (welche Kits?), `validate` (PRs, ohne Secrets) und `publish` (nur `main`, Environment `docker-hub`).
- [`dart_test_tools_ci.yml`](../.github/workflows/dart_test_tools_ci.yml): Job `sbx-kits`, dazu in den `needs` des Renovate-Jobs.
- [`sbx/tool/kit-version.sh`](../sbx/tool/kit-version.sh) löst `version:` auf, auch `${{ kit.args.* }}`, was ein Workflow nicht selbst schreiben kann. [`sbx/tool/check-attestations.sh`](../sbx/tool/check-attestations.sh) prüft Provenance und SBOM pro Plattform, im OCI-Layout oder in der Registry.
- Descriptoren: Frontend per Digest gepinnt, `licenses`, Marken-Hinweis. Dockerfile: `docker/dockerfile:1` und `debian:trixie-slim` per Digest.
- `renovate.json`: Regex-Manager hält die drei Digest-Pins aktuell. Digest-Updates von Frontend und Dockerfile-Syntax laufen im wöchentlichen PR mit. Ein Wechsel des Tags (z. B. `sandbox-kit:3` → `:4`) braucht eine manuelle Migration. Er kommt deshalb als eigener PR (`renovate/sbx-frontends`) und erst nach Freigabe im Dependency Dashboard.
- READMEs: veröffentlichte Referenzen, Tags, Prüfung von Signatur und Attestation, Lizenzen, Marke.

Ablauf beim Veröffentlichen, pro Kit (alles in einem Job):

1. Bauen mit `provenance: mode=max`, `sbom: true`, `pull: true`, `no-cache: true`, und **nur per Digest pushen** (`push-by-digest=true`). Bis Schritt 7 zeigt kein Tag auf das Kit.
2. Prüfen, dass jede Plattform eine SLSA-Provenance und ein SPDX-SBOM hat und es genau zwei Plattformen sind.
3. `kit-tck validate <image>@<digest>`.
4. `sbx kit sign <image>@<digest>` (keyless, Rekor-Eintrag öffentlich). Die Signatur liegt auf dem **Index**. Weil der Index die Plattform- und Attestation-Manifeste per Digest auflistet, deckt sie auch die sonst unsignierte BuildKit-Provenance ab.
5. `actions/attest` (SLSA-Provenance, von GitHub signiert, als Referrer in die Registry gepusht). `create-storage-record: false`: Storage Records bräuchten zusätzlich die Berechtigung `artifact-metadata: write` und sind für Organisationen gedacht.
6. Verifizieren:
   - `sbx kit verify` mit exakter Identität `https://github.com/Skycoder42/dart_test_tools/.github/workflows/sbx-kits.yml@refs/heads/main` und Issuer `https://token.actions.githubusercontent.com`;
   - `gh attestation verify` mit `--signer-workflow`, `--source-ref refs/heads/main`, `--source-digest <sha>` und `--deny-self-hosted-runners`, einmal über die GitHub-API und einmal aus der Registry (`--bundle-from-oci`).
7. Tags per `docker buildx imagetools create --prefer-index=false` setzen. Das ist eine bytegleiche Kopie, der Digest bleibt also gleich. Danach wird geprüft, dass jedes Tag genau auf den Digest zeigt.

Härtung:

- Actions per SHA gepinnt (Dependabot aktualisiert sie).
- Workflow-weit `permissions: {}`. `id-token` und `attestations: write` hat nur der Publish-Job. Überall `persist-credentials: false`.
- Publish nur, wenn `github.ref == refs/heads/main`, im Environment `docker-hub`, und mit Job-`concurrency` pro Kit (kein Rennen um `latest`).
- Kein Build-Cache und immer `pull`, also kein Cache-Poisoning über PR-Läufe.
- Alle Eingaben gepinnt: Frontend, Dockerfile-Syntax und Basis-Image per Digest. Der Flutter-Tag wird gegen den Release-Index geprüft, die Skills sind per Commit gepinnt. kit-tck per SHA-256, `sbx` per apt-Version und Schlüssel-Fingerprint, wobei apt nur die eine Quelle sieht.
- Workflow-Ausdrücke landen nur über `env:` in Shell-Skripten.

#### P3.5 Risiken: nicht oder nicht vollständig härtbar

| # | Punkt | Warum | Was es bräuchte |
|---|---|---|---|
| R1 | Das Docker-Hub-Token ist **nicht auf ein Repository beschränkbar** und hat Schreibrecht auf alle Repositories des Accounts. | Persönliche Access Tokens kennen keine Repository-Scopes. Access Tokens mit Repository-Scope und OIDC gibt es nur für Organisationen. | Docker-Organisation (DSOS ist für Open Source kostenlos) plus OIDC-Connection mit Regel auf `repo:Skycoder42/dart_test_tools:environment:docker-hub`. Bis dahin: Token mit Scope „Read & Write“ (nicht „Delete“), nur im Environment `docker-hub`, Deployment-Branch nur `main`. |
| R2 | `sbx kit verify` und `kit.trustedSigners` prüfen nur Identität und Issuer. | Anders als cosign kennt `sbx` keine Prüfung von Trigger, Repository-ID oder Runner. | Die exakte Workflow-Identität auf `main` ist das Strengste, was Nutzer*innen haben. Den Rest prüft CI per `gh attestation verify`. |
| R3 | kit-tck: `checksums.txt` ist unsigniert. Der SHA-256-Pin vertraut also dem Stand beim Pinnen (TOFU). | Upstream veröffentlicht weder Signatur noch Attestation. | Signierte Releases upstream. kit-tck läuft nur als Prüfwerkzeug und nicht mit den Push-Rechten des Images. Es läuft aber im selben Job wie das Docker-Token. |
| R4 | `sbx` in CI ist 0.51.0, lokal 0.53.0. | Nur das apt-Repository ist signiert und hängt hinterher. | Ein Update, sobald apt nachzieht. Der Versions-Pin wird von Hand gepflegt, ebenso der kit-tck-Pin (kein Renovate-Manager). |
| R5 | ⚠️ `sbx kit sign` an einem v3-**Index** und das Nebeneinander mit dem Attestation-Referrer von `actions/attest` sind ungetestet. Ebenso offen: ob `sbx` dafür `sbx login` oder einen Daemon braucht. | Kein Vorbild (Dockers Kits sind unsigniert), lokal kein BuildKit mit Kit-Frontend (`docker` ist Podmans Shim). | Der erste CI-Lauf. `sbx kit verify` mit exakter Identität schlägt fehl, bevor ein Tag gesetzt wird. |
| R6 | ⚠️ SBOM über das Custom-Frontend. | Siehe P3.3. | Der erste CI-Lauf. Schlägt er fehl, ist die Entscheidung: SBOM weglassen oder separat erzeugen (z. B. `actions/attest` im SBOM-Modus). |
| R7 | ⚠️ kit-tck `--layout <dir> <tag>`: Das Tag im OCI-Layout wird als `<version>` angenommen (Image-Name `sbx-kit-<kit>:<version>`). | Nicht lokal prüfbar. | Der erste PR-Lauf. |
| R8 | Gebaut wird mit QEMU (arm64 emuliert). | Siehe P3.3. | Bei Timeouts native arm64-Runner, dann müssten aber die Index-Annotationen wiederhergestellt werden. |
| R9 | ⚠️ Index-Annotation `org.opencontainers.image.revision` beim Push per Digest über das Custom-Frontend. | Nicht lokal prüfbar. | Ab dem zweiten Publish im Log von `changes` sichtbar („unchanged since …“). Fehlt sie, wird nur unnötig neu gebaut, nichts wird schwächer. |

#### P3.6 Vor dem ersten Lauf (von Hand)

1. GitHub-Environment `docker-hub` anlegen: Deployment-Branch nur `main`, Secrets `dockerHubUsername` und `dockerHubToken` (Token-Scope „Read & Write“).
2. Nach dem ersten Publish: Docker-Hub-Repositories `skycoder42/sbx-kit-{flutter,flutter-linux,flutter-web}` öffentlich, Beschreibung mit Marken-Hinweis. Unter „Tag mutability settings“ „Specific tags are immutable“ mit `^[0-9]+\.[0-9]+\.[0-9]+-[0-9a-f]{40}$` setzen ([Docs](https://docs.docker.com/docker-hub/repos/manage/hub-images/immutable-tags/)).
3. Optional: das Set `sbx-kit-claude-flutter` mit `resources@1`, digest-gepinnt (aus dem ursprünglichen Plan, noch offen).

### Phase 4: Doku und Rollout
- README pro Kit plus Abschnitt im Haupt-README: Nutzung, Ressourcen-Empfehlung (`--cpus 4 --memory 8g`), bekannte Grenzen (kein iOS/macOS)
- Optional: die Repo-Skills (`skills/dart-test-tools-*`) als `agent-skill@1`-Mixin ausliefern
- ~~Optional: Dart-MCP-Server (`dart mcp-server`) für den Agenten registrieren.~~ **Umgesetzt 2026-11-14** in [`sbx/flutter/`](../sbx/flutter/): `sbx mcp` scheidet aus, weil diese Server auf dem Host laufen, ohne SDK und ohne Sandbox-Workspace. Stattdessen registriert ein `startup`-Hook (als `agent`) den Server per `claude mcp remove/add --scope user dart -- /opt/flutter/bin/dart mcp-server`. Das ist dasselbe Muster, mit dem der `claude`-Workload sein `mcp-gateway` registriert. Fehlt `claude`, wird der Hook übersprungen. Getestet mit `sbx env create` (`claude` + `flutter`): Der Hook läuft beim Boot, `claude mcp get dart` meldet „Connected“. Offen: weitere Agents (`codex mcp add`, `gemini mcp add`).
- ~~Optional: offizielle Dart- und Flutter-Skills mitliefern.~~ **Umgesetzt 2026-11-14** in [`sbx/flutter/`](../sbx/flutter/): Eine eigene Build-Stage holt [`dart-lang/skills`](https://github.com/dart-lang/skills) (`dart-*`, die Quelle) und [`flutter/agent-plugins`](https://github.com/flutter/agent-plugins) (`flutter-*`; die `dart-*`-Kopie dort ist nur ein Sync). Beide Repos haben keine Release-Tags, deshalb sind sie per Commit gepinnt (Build-Args `dartSkillsRef`, `flutterSkillsRef`). Die Skills landen unter `/opt/flutter-skills/<name>`, und für jeden gibt es einen optionalen `agent-skill@1`-Eintrag. Die Runtime verlinkt sie in das `agent-skills@1`-Verzeichnis des Agents (`~/.claude/skills`, `~/.agents/skills` …), das funktioniert also unabhängig vom Agent. `agent-skill@1` verlangt literale Pfade, deshalb bricht der Build ab, wenn sich die Skill-Liste upstream ändert (`SKILLS` im Dockerfile und Descriptor gemeinsam anpassen). Nicht übernommen aus agent-plugins: Plugin-Manifest (MCP ist schon registriert), die `rules/` (Hot Reload) und die Stop-Hooks. Getestet: 25 Symlinks in `~/.claude/skills`, Claude Code listet alle 25 Skills.

---

## 5. Offene Fragen und Risiken

| # | Thema | Risiko | Klärung |
|---|---|---|---|
| 1 | Image-Größe (Flutter precached) und Startzeit | mittel | in Phase 1 messen |
| 2 | arm64: Flutter nur per Git | mittel | Phase 0 |
| 3 | Kit-Format v3 ist **experimentell**, der Grammar ändert sich noch | mittel | Spec-Version im Frontend pinnen (`docker/sandbox-kit:3`), `sbx`-Mindestversion dokumentieren |
| 4 | `storage.googleapis.com` ist breit freigegeben | niedrig/Sicherheit | `network-policy@2`-Pfad-Bounds, Phase 0 |
| 5 | ENV-Kollisionen mit anderen Mixins (`CHROME_EXECUTABLE`) | niedrig | in `/etc/profile.d` statt `ENV`, falls nötig |
| 6 | Org-Policy der Sandbox (Governance) überschreibt die Kit-Allow-List | niedrig | mit Admins abstimmen |
