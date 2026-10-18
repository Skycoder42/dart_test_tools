---
name: dart-test-tools-native-update
description: >-
  Use when the user wants to update the native platform projects of a flutter app
  (android/, ios/, linux/, macos/, web/, windows/) to the templates of the installed
  Flutter SDK — typically after a Flutter minor release, or when a native build fails
  because of outdated Gradle, AGP, Kotlin or deployment targets. Regenerates the templates
  over a clean working tree, keeps the template-driven updates, restores the project's own
  identifiers and customisations, and reports everything it threw away.
license: BSD-3-Clause
user-invocable: true
allowed-tools:
  - Bash(bash ${CLAUDE_SKILL_DIR}/scripts/native-update.sh:*)
  - Bash(git diff:*)
  - Bash(git show:*)
---

# Native project updates

The native projects of a flutter app are generated once by `flutter create` and then
belong to the project. Nothing updates them afterwards — neither `flutter upgrade` nor the
dependency update. Over time they fall behind what current plugins expect (a Gradle or
Android Gradle Plugin version, a Kotlin version, a macOS or iOS deployment target), until a
native build breaks.

This skill catches them up: it regenerates the templates of the installed Flutter SDK over
the existing projects and then merges the result by hand — taking what the template
changed, restoring what the project changed.

The goal is **correctness and up-to-date-ness**. Take every change that brings the build
infrastructure in line with the current template. Never take a change that overwrites
something the project chose for itself.

Throughout: **never commit, never push, never stage.** Working-tree changes plus a report
are the whole output.

---

## Phase 1 — regenerate the templates

```sh
bash ${CLAUDE_SKILL_DIR}/scripts/native-update.sh regenerate
```

- It refuses to run unless the working tree is **completely clean**, untracked files
  included. Every change it leaves behind must come from the template, so that git can
  tell template and project apart. On a dirty tree, relay that and stop — the user commits
  or stashes. Do not work around it.
- It finds every flutter **app** project — a tracked `.metadata` with `project_type: app`.
  It runs `flutter create --overwrite --empty --no-pub` over each one, for exactly the
  platform folders the project already has. It never adds a platform.
- Then it resets everything the template touched outside the **native scope**: the
  platform folders, plus the top-level files of the project except `pubspec.yaml` and
  `pubspec.lock`. Typical resets are `lib/main.dart` and the pubspec. They were never
  candidates.

Run it once. Do not run `flutter create` yourself, and do not use `git restore`,
`git checkout` or `rm` to throw changes away — use `discard` (below).

### The record

The script prints a record on stdout, in the same format as the
`dart-test-tools-auto-update` skill:

- It sits between `>>> native-update` and `<<< native-update`.
- Each line is one `key: value` pair. Keys may be dotted and indexed.
- Everything after the first `: ` belongs to the value.
- `warning` may appear any number of times.

Always present:

| Key | Meaning |
| --- | --- |
| `status` | `ok`, or `error` (then `error` says why) |
| `action` | `regenerate`, `status` or `discard` |
| `repo_root` | absolute path of the repository; every path in the record is relative to it |
| `project_count` | how many `project.<n>.*` groups follow |
| `project.<n>.path` | the project directory (`.` for the repository root) |
| `project.<n>.name` | its package name |
| `project.<n>.platforms` | the platforms that were regenerated |
| `project.<n>.previous_revision` | the Flutter revision the templates were last generated with, from `.metadata` in `HEAD` |
| `change_count` | how many `change.<n>.*` groups follow — the changes **currently** in the working tree |
| `change.<n>.path` | the changed file |
| `change.<n>.project` | the project it belongs to (`0` when it belongs to none) |
| `change.<n>.area` | `root` (top-level project file), the platform (`android`, …), or `outside` |
| `change.<n>.kind` | `modified`, `added` (new, untracked) or `deleted` |
| `change.<n>.content` | `text`, `binary`, or `whitespace` (nothing but whitespace and blank lines changed) |
| `change.<n>.stat` | `+added -removed` lines, or `binary` |

Only for `regenerate`:

| Key | Meaning |
| --- | --- |
| `flutter_version` / `flutter_revision` | the SDK the templates came from |
| `project.<n>.create_exit_code` / `project.<n>.create_log` | the `flutter create` run |
| `diff` | the full regenerated diff (tracked files) — the baseline for the final report |
| `reset_count`, `reset.<n>.path` | what was reset outside the native scope |

Only for `discard`: `discarded_count`, `discarded.<n>.path`.

### Before moving on

- **`status: error`** — relay it and stop. If a `flutter create` run failed, the script has
  already reset the tree. Read the log it names.
  - If flutter could not work out the project's organisation, ask the user for it.
    Then run `regenerate --org <org>`. The organisation only feeds identifiers, which get
    restored anyway.
- **`project_count: 0`** — there is nothing to update. Say so and stop.
- **Always surface every `warning`.** A disagreement between the platform folders and
  `.metadata` means `.metadata` is stale or a platform folder went missing. The user should
  know about it either way.
- If a listed platform has no changes at all, check its `create_log` before concluding the
  template simply did not change. Desktop platforms need their `flutter config` switch
  enabled.

---

## Phase 2 — evaluate every change

Go through the changes **project by project**. Within a project, start with `root`, then
take one platform at a time. Alphabetical order is fine. Read each diff with
`git diff -- <path>`, and read new files directly.

Decide for every change — down to the individual hunk — whether it is **template-driven**
(keep) or **project-owned** (restore). A single file often holds both. Example: a
`project.pbxproj` where the deployment target is a template update, but the product name
is the project's.

### Keep — the template moved on

- **Versions of the build tooling:**
  - the Gradle wrapper distribution
  - Android Gradle Plugin, Kotlin and other plugin versions in `settings.gradle(.kts)`
  - Java/JVM source and target levels
  - the NDK version
  - CMake minimum versions
  - deployment targets: `MACOSX_DEPLOYMENT_TARGET`, `IPHONEOS_DEPLOYMENT_TARGET`, the
    `platform :ios` / `platform :osx` line of a `Podfile`
  - Xcode `objectVersion`, `LastUpgradeCheck` and compatibility settings
- **Changes to build scripts and runner code** that are not about identity:
  - new or changed logic in Gradle files, `CMakeLists.txt` or Xcode build phases
  - changed build settings
  - changed boilerplate in `MainActivity`, `AppDelegate`, `main.cpp`, `my_application.cc`
  - `gradle.properties` flags
- **Template markup and configuration fixes**, e.g. `async=""` → `async` in
  `web/index.html`.
- **`.gitignore` entries the template adds or changes**, e.g. `.cxx` → `.cxx/` or a new
  `.widget_preview/` section. Insert them where the template puts them, between the
  project's own entries.
- **`.metadata`**: take the revision bumps, but keep everything in the user-provided
  section (`unmanaged_files` and the like).
- **New files** that are genuinely new build infrastructure and do not duplicate anything
  the project already has.

### Restore — the project owns it

- **Identifiers**:
  - application IDs, namespaces, bundle identifiers, Kotlin/Java package paths
  - `APPLICATION_ID`, `BINARY_NAME`, `PRODUCT_NAME`
  - display names, window titles, labels, copyright strings, the web manifest `name` and
    `short_name`
- **Customisations and additions**:
  - signing configurations
  - overrides of template defaults (`minSdk = 26` instead of `flutter.minSdkVersion`)
  - extra Gradle dependencies or plugins
  - permissions, intent filters, `<meta-data>`, `Info.plist` keys, entitlements
  - styles and themes, launch screens, splash content
  - the custom content of `index.html`
  - web manifest colours, description and icons
  - `.gitignore` entries the template drops
- **Assets**: every binary change — launcher and app icons, favicons, `app_icon.ico`. Also
  new default assets the project does not use, such as the web `icons/Icon-*.png` when it
  ships its own.
- **New files that duplicate existing ones**. Example: a `MainActivity.kt` under a new
  package path, because the template derived a different identifier.
- **New files the project ignores**. Judge them against the project's own `.gitignore`,
  not the template's. Example: generated plugin registrants.
- **New top-level files the project gets elsewhere**, e.g. an `analysis_options.yaml` when
  the workspace root already has one.
- **Whitespace- and formatting-only changes** (`content: whitespace`, or reflowed XML
  without semantic changes).

Do not make changes the template did not make. Stale entries are not part of the update —
for example, a `.gitignore` line for a file the project no longer has. Point them out in
the report; do not remove them.

### When it is unclear, ask

Some changes have no obvious owner. Ask the user rather than guess, and batch the
questions (up to four at a time) instead of asking one by one. Typical cases:

- **The template removes a line, and you cannot tell who wrote it.** Generic,
  project-agnostic wording suggests an older template, so the removal is an update.
  Project-specific values suggest a customisation.
- **The template changes something the project overrides.** For example, it moves how a
  value is set, while the project pins its own value. Name both options.
- **A new template file that might be useful** but is not clearly infrastructure.
- **An override whose comment says it is temporary**, such as "revert once flutter caught
  up". Ask whether the new template makes it obsolete — do not decide it alone.

### How to apply the decisions

- **Whole files and folders**: run
  `bash ${CLAUDE_SKILL_DIR}/scripts/native-update.sh discard <path>...`.
  - It takes several paths at once.
  - A folder discards every change below it.
  - It refuses paths outside the native scope.
  - Its record lists what is left.
- **Parts of a file**: edit the file so that the project-owned hunks read exactly as they
  do in `HEAD` again, and the template hunks stay. `git diff -- <path>` shows the original
  lines. When only a small template change is worth keeping in a heavily rewritten file,
  it is often easier to `discard` the whole file and re-apply that one change by editing.
- **Order matters for `.gitignore`**: settle the `.gitignore` files first. Whether a new
  untracked file should be dropped depends on what the restored `.gitignore` ignores.

### Check the result

Finish with:

```sh
bash ${CLAUDE_SKILL_DIR}/scripts/native-update.sh status
```

Every remaining change must be one you decided to keep — hunk for hunk. Check with
`git diff`. There must be no `outside` changes. A project, or a single platform, may
legitimately end up with no changes at all.

Do not try to build the native projects. That needs platform toolchains, signing and often
other operating systems. CI covers it.

---

## Phase 3 — report

Tell the user:

- **The Flutter version** the templates came from, and the revision they were last
  generated with, per project.
- **What was kept**, per project and platform, with old → new values where there are any.
  Example: Gradle 9.1.0 → 9.3.1, MACOSX_DEPLOYMENT_TARGET 10.15 → 12.0.
- **Everything that was discarded**, compared against the regenerated `diff` and the
  untracked files of the first record. This list must be complete:
  - Every discarded change that is **not purely an identifier**, each with the reason —
    customisation, asset, duplicate, ignored, formatting.
  - Identifier-only restores (IDs, names, titles) may be summed up in a single line.
  - The out-of-scope resets in one line.
- **Every question still open**, with the decision you need.
- **Anything you noticed but deliberately left alone**: stale entries, temporary overrides
  that might be obsolete now.
- **Which platforms changed**, so the user knows which CI builds verify the update.

Then stop. The user commits.
