# syntax=docker/dockerfile:1
ARG BUILD_IMAGE=docker.io/library/debian:trixie-slim

FROM ${BUILD_IMAGE} AS base
RUN apt-get update \
 && apt-get install -y --no-install-recommends ca-certificates curl git jq unzip xz-utils \
 && rm -rf /var/lib/apt/lists/*

FROM base AS build
ARG FLUTTER_VERSION
ARG DART_VERSION
ARG FLUTTER_RELEASES_URL=https://storage.googleapis.com/flutter_infra_release/releases/releases_linux.json

RUN useradd --uid 1000 --create-home agent \
 && install -d -o 1000 -g 1000 /opt/flutter
USER 1000:1000

RUN set -eux; \
    curl -fsSL "$FLUTTER_RELEASES_URL" \
      | jq -e --arg v "$FLUTTER_VERSION" \
          'first(.releases[] | select(.channel == "stable" and .version == $v))' \
      > /tmp/release.json; \
    test "$(jq -r .dart_sdk_version /tmp/release.json)" = "$DART_VERSION"; \
    cd /opt/flutter; \
    git init -q -b stable; \
    git remote add origin https://github.com/flutter/flutter.git; \
    git fetch -q --depth 1 origin "refs/tags/${FLUTTER_VERSION}:refs/tags/${FLUTTER_VERSION}"; \
    git reset -q --hard "refs/tags/${FLUTTER_VERSION}"; \
    test "$(git rev-parse HEAD)" = "$(jq -r .hash /tmp/release.json)"; \
    git update-ref refs/remotes/origin/stable HEAD; \
    git branch -q --set-upstream-to=origin/stable stable

ENV PATH=/opt/flutter/bin:$PATH \
    PUB_CACHE=/tmp/pub-cache
RUN set -eux; \
    flutter config --no-analytics; \
    dart --disable-analytics; \
    flutter precache --universal --linux --web; \
    flutter --version --machine > /tmp/version.json; \
    jq -e --arg v "$FLUTTER_VERSION" '.frameworkVersion == $v and .channel == "stable"' /tmp/version.json; \
    jq -e --arg v "$DART_VERSION" '.dartSdkVersion | startswith($v)' /tmp/version.json; \
    dart --version 2>&1 | grep -q "Dart SDK version: ${DART_VERSION} "; \
    rm -rf /opt/flutter/bin/cache/downloads

FROM base AS skills
ARG DART_SKILLS_REF
ARG FLUTTER_SKILLS_REF
ARG SKILLS
RUN <<'SH'
set -eux
test -n "$SKILLS"
fetch() {
  git init -q "$1"
  git -C "$1" fetch -q --depth 1 "$2" "$3"
  git -C "$1" checkout -q FETCH_HEAD
  test "$(git -C "$1" rev-parse HEAD)" = "$3"
}
fetch /tmp/dart-skills https://github.com/dart-lang/skills.git "$DART_SKILLS_REF"
fetch /tmp/flutter-skills https://github.com/flutter/agent-plugins.git "$FLUTTER_SKILLS_REF"

out=/out/opt/flutter-skills
mkdir -p "$out/LICENSES"
cp -a /tmp/dart-skills/skills/dart-* "$out/"
cp -a /tmp/flutter-skills/skills/flutter-* "$out/"
cp /tmp/dart-skills/LICENSE "$out/LICENSES/dart-lang-skills"
cp /tmp/flutter-skills/LICENSE "$out/LICENSES/flutter-agent-plugins"

# The bundled set must be exactly the declared one.
test "$(cd "$out" && ls -d dart-* flutter-* | sort)" = "$(printf '%s\n' "$SKILLS" | sort)"
printf '%s\n' "$SKILLS" | while IFS= read -r skill; do
  test -f "$out/$skill/SKILL.md"
  test ! -L "$out/$skill/SKILL.md"
  # agent-skill@1 keeps the frontmatter as is: it must match the directory.
  sed -n '2,/^---$/p' "$out/$skill/SKILL.md" | grep -qx "name: $skill"
done
test -z "$(find "$out" -type l)"
chmod -R a+rX,go-w "$out"
SH

FROM scratch
COPY --from=build /opt /opt
COPY --from=skills --chown=0:0 /out /
ENV PATH=/opt/flutter/bin:/home/agent/.pub-cache/bin:$PATH
