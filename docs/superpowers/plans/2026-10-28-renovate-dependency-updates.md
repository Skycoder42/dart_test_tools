# Renovate Dependency Updates Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Replace the reusable auto-update workflow and `auto-update` CLI with self-hosted Renovate (reusable `renovate.yml`, shared presets, a `renovate-post-upgrade` CLI run as `postUpgradeTasks`) plus a reusable `renovate-finish.yml`.

**Architecture:** Consumers call `renovate.yml@main` on a weekly cron. It installs Flutter and dart_test_tools, writes a Renovate global config via the new `renovate-config` CLI, and runs `npx renovate` on the runner (`binarySource: global`) with the job's `GITHUB_TOKEN`. Presets in `renovate/` decide what to update; the `renovate-post-upgrade` CLI does resolution, analyzer plugin sync, build_runner/format/fix and cider inside Renovate's commit. The owner is requested as reviewer when the PR opens and approves the CI runs. Consumer CI ends with a job calling `renovate-finish.yml`, which merges a green Renovate PR (pinned to the approved SHA) and dispatches CI on the default branch, or comments with a mention on a red one.

**Changed 2026-10-29 (after Tasks 0–4 were done):** GitHub App replaced by `GITHUB_TOKEN`, `notify.yml` replaced by `renovate-finish.yml` (spec: Decisions, Components 1/4/5, Security model). Tasks 0–4 are left as they were; the re-verification lives in the new Task 4a, Tasks 5–12 are adjusted.

**Tech Stack:** Dart 3 (primary-constructor syntax as used throughout the repo), `args`, `pubspec_parse`, `yaml_edit`, `freezed`/`json_serializable`, the `tool/ci_gen` workflow generator, Renovate 44 (npm), GitHub Actions.

**Spec:** `docs/superpowers/specs/2026-10-27-renovate-dependency-updates-design.md`

## Global Constraints

- `.github/workflows/*.yml` and `.github/actions/*/action.yml` are generated: change `tool/ci_gen/**`, then run `dart run tool/ci_gen.dart`. The `dart_test_tools_*.yml` callers are hand-written.
- Changelog/version only via `dart run bin/cider.dart …` (never edit `CHANGELOG.md` or the pubspec version by hand).
- Analyze with the Dart MCP server (`mcp__dart__analyze_files`), not `dart analyze`.
- Renovate pinned (exact, ≥ **44.164.5**) in `tool/renovate/package.json` + `tool/renovate/package-lock.json` (changed 2026-10-30, was a `renovateVersion` input); Node from its `engines.node` (`^24.11.0`). This repo's own Renovate updates both. Actions use their latest major tags (user preference: latest versions).
- Renovate token = the job's `GITHUB_TOKEN` with exactly: contents write, pull-requests write, issues write, statuses write. No GitHub App, no PAT, no secrets in any of the new workflows.
- Finish job token (`GITHUB_TOKEN`) exactly: contents write, pull-requests write, actions write. It acts only on PRs by `github-actions[bot]` from a same-repo `renovate/` branch and merges only with `--match-head-commit` of the run's PR head SHA.
- Renovate global config: `onboarding: false`, `requireConfig: "required"`, `binarySource: "global"`, `repositoryCache: "enabled"`, `executionTimeout: 30`, `allowedCommands: ["^renovate-post-upgrade --mode (application|library)$"]`.
- Presets: `enabledManagers: ["pub"]`, `rangeStrategy: "bump"`, `prHourlyLimit: 0`, `vulnerabilityAlerts.enabled: false`, no `schedule`, no `reviewers` (set by the workflow via `RENOVATE_REVIEWERS`), no `automerge`; SDK rule `versioning: "npm"` + `allowedVersions: "/^\\d+\\.\\d+\\.0$/"`.
- Changelog copy: `Updated dependencies`; SDK lines `Updated min sdk version to <constraint>` / `Updated min flutter version to <constraint>`.
- No commits until the user says so: the user wants spec, plan and implementation committed together. Every "Commit" step below means: stage only (`git add`), do not `git commit`.

## Review Focus

1. Workspace where only member pubspecs changed (root pubspec untouched): root `pubspec.lock` must still be regenerated → test in Task 3.
2. `build_runner` declared only in a workspace member, not the root: build_runner must still run → test in Task 3.
3. Data file containing only SDK upgrades (`dart`/`flutter`): resolution + SDK changelog lines, no "Updated dependencies" duplication issues → test in Task 3.
4. Package not at repo root (pubspec in `sub/dir/`, not a workspace): processed from its own directory → test in Task 2.
5. Same dep updated in several members (duplicate data file entries per package file): each package gets exactly one changelog entry and one patch bump → test in Task 3.

---

### Task 0: Spike in the test repo — ✅ DONE 2026-10-28

Results are recorded in the spec ("Phase 0 — spike"). The working spike files in
`Skycoder42/renovate-test` are the reference implementation for Tasks 4, 6, 7 and 8. The steps
below are kept for the record only.

**Prerequisites (user):** GitHub App with the permissions above; a test repo with the App installed and secrets `renovateAppId` / `renovateAppPrivateKey`; the repo is a pub workspace with `packages/pure` (Dart) and `packages/app` (Flutter, `environment.flutter`), a committed root `pubspec.lock`, outdated deps incl. one major, one 0.x dep, an old `sdk: ^3.6.0` / `flutter: ">=3.24.0"`, and `build_runner` in `packages/pure` only. A second branch without lockfile for the library preset.

**Files (test repo only, nothing in dart_test_tools):** `.github/workflows/renovate-spike.yml`, `renovate.json`, `spike-presets/{base,library,application}.json`, `spike/post-upgrade.sh` (stub: `flutter pub get`, `dart format .`, `echo` of the data file).

- [ ] **Step 1:** Write the spike workflow by hand (App token → subosito → setup-node 24 → write global config → `npx --yes renovate@<pin>`), presets as in spec Component 2, `allowedCommands: ["^bash spike/post-upgrade.sh$"]`.
- [ ] **Step 2:** Run with the application preset. Record: S1 root `pubspec.lock` committed in Renovate's commit; S2 exactly one branch `renovate/all`, postUpgradeTasks ran once (branch mode) and the data file JSON is what Task 1 parses (paste one real sample into the spec); S3 SDK constraints became `^3.x.0` / `>=3.y.0`, `custom.flutter-dart` datasource used.
- [ ] **Step 3:** Add global `packageRules` with `allowedVersions: "<=<pin>"` for one Flutter-pinned package (e.g. `collection`). Record S4: the rule holds despite the repo's own `renovate.json`.
- [ ] **Step 4:** Record S5: presets fetched via `github>Skycoder42/dart_test_tools//<path>` from a branch of the public repo with the repo-scoped token (push the spike presets to a scratch branch of dart_test_tools only if the user agrees; otherwise from a public scratch repo).
- [ ] **Step 5:** Switch to the library preset (no lockfile branch). Record S8: majors and 0.x minors appear in the dashboard only; the weekly PR is not held; ticking one opens a separate "breaking" PR.
- [ ] **Step 6:** Notify: in the test repo, a hand-written job that requests/re-requests the owner on the Renovate PR via `gh api` with GITHUB_TOKEN. Run CI twice (push an empty commit by hand in between). Record S6: which sequence (POST `requested_reviewers` / POST `…/requested_reviewers/rerequest` / DELETE+POST) yields a mobile push on the 1st and 2nd run.
- [ ] **Step 7:** Record S7: behaviour of `packages/app` depending on `packages/pure` by version only (lookup warning / bogus update) and the ignore rule that fixes it.
- [ ] **Step 8:** Write all findings into a new "Spike findings" section of the spec, adjust the presets section where reality differs, and stop for user review. Fallbacks if an item fails: S4 → `renovate-config` writes pins into a generated preset file passed via global `extends` instead; S5 → install the App on dart_test_tools too and add it to `repositories` of the token; anything else that changes user-visible behaviour → back to the user.

---

### Task 1: Renovate data file model — ✅ DONE 2026-10-28

**Files:**
- Create: `lib/src/renovate/models/renovate_upgrade.dart` (freezed + json, like `lib/src/auto_update/models/pub/**`)
- Create: `lib/src/renovate/upgrade_data.dart`
- Test: `test/integration/renovate/upgrade_data_test.dart`

**Interfaces:**
- Produces: `RenovateUpgrade({required String depName, required String packageFile, String? depType, String? currentValue, String? newValue, String? updateType})` with `fromJson`; `bool get isSdkUpgrade` (`depName` is `dart` or `flutter`); `String get sdkKey` (`'sdk'` for `dart`, `'flutter'` for `flutter`).
- Produces: `abstract final class UpgradeData { static const dataFileEnvVar = 'RENOVATE_POST_UPGRADE_COMMAND_DATA_FILE'; static Future<List<RenovateUpgrade>> load(File file); static Future<List<RenovateUpgrade>> fromEnvironment(); }` — `fromEnvironment` throws `StateError` if the env var is missing.
- The JSON shape is fixed by the `dataFileTemplate` in Task 7: a top-level array of objects with the six keys above (format confirmed in spike S2). Renovate renders absent values as `""` (e.g. `depType` of SDK entries) — the model maps `""` to `null`.

- [ ] **Step 1: Write failing tests** — `load parses all fields` (use this real spike entry as fixture: `{"depName":"dart","packageFile":"packages/pure/pubspec.yaml","depType":"","currentValue":"^3.6.0","newValue":"^3.13.0","updateType":"minor"}` plus one regular dependency entry), `empty strings become null`, `load accepts missing optional fields`, `isSdkUpgrade and sdkKey for dart/flutter/other`, `fromEnvironment throws StateError without env var` (use a temp file; the last test runs in a `Process`-free way by injecting env through a `@visibleForTesting static Map<String, String> Function() environment` hook).
- [ ] **Step 2:** Run `dart test test/integration/renovate/upgrade_data_test.dart` → FAIL (missing files).
- [ ] **Step 3:** Implement; run `dart run build_runner build` for freezed/json parts.
- [ ] **Step 4:** Run the tests → PASS; analyze via MCP → no issues.
- [ ] **Step 5:** Stage files.

---

### Task 2: Pub root resolution — ✅ DONE 2026-10-28

**Files:**
- Create: `lib/src/renovate/pub_roots.dart`
- Test: `test/integration/renovate/pub_roots_test.dart`

**Interfaces:**
- Consumes: `RenovateUpgrade.packageFile` (repo-relative path to a `pubspec.yaml`).
- Produces: `class PubRoots(final Directory repoRoot) { Future<List<Directory>> resolve(Iterable<String> packageFiles); }` — for each file: its directory; if that pubspec has `resolution: workspace`, walk up until a pubspec with a non-empty `workspace:` list is found (throw `StateError` naming the member if none). Deduplicate by absolute path, keep first-seen order.

- [ ] **Step 1: Write failing tests** (temp dirs with hand-written pubspecs): `plain package at root → [root]`, `package in sub/dir → [sub/dir]` (Review Focus 4), `two members of one workspace → [workspace root] once`, `member without workspace parent → StateError`.
- [ ] **Step 2:** Run → FAIL.
- [ ] **Step 3:** Implement with `pubspec_parse` (`Pubspec.workspace`, `resolution` read via `package:yaml` since `pubspec_parse` may not expose it — check first).
- [ ] **Step 4:** Run → PASS; analyze.
- [ ] **Step 5:** Stage.

---

### Task 3: Post-upgrade runner — ✅ DONE 2026-10-28

**Files:**
- Create: `lib/src/renovate/post_upgrade.dart`
- Move: `lib/src/auto_update/pub_wrapper.dart`, `sdk_iterator.dart`, `models/**` → `lib/src/pub/` (update imports; keep `@internal`)
- Modify: `lib/src/pub/pub_wrapper.dart` — add `Future<void> get()`; change `dependsOnBuildRunner()` to check every workspace package (via `workspaceList()`), not only the root (Review Focus 2)
- Test: `test/integration/renovate/post_upgrade_test.dart`

**Interfaces:**
- Consumes: `UpgradeData`, `RenovateUpgrade`, `PubRoots` (Tasks 1–2).
- Produces: `enum PostUpgradeMode() { application, library }` and `class PostUpgrade({required final PostUpgradeMode mode}) { Future<void> call(Directory repoRoot, List<RenovateUpgrade> upgrades); }`.
- Behaviour per pub root, in order: (1) `PubWrapper.create(root)` — Flutter detection must be true if any workspace package depends on the Flutter SDK (verify `_isFlutterProject` via `pub deps` at a workspace root covers members; fix if not); (2) `upgrade()` for application, `get()` for library; (3) analyzer plugin pin sync (logic moved from `Updater._updateAnalyzerPlugins`); (4) build_runner if any package depends on it, `format`, `fix`, `format` (from `Updater._autoFix`); (5) for every workspace package that is not a workspace root and has a `CHANGELOG.md`: one `cider log changed "Updated min <sdkKey> version to <newValue>"` per *distinct* SDK upgrade whose `packageFile` is this package's pubspec, then `cider log changed "Updated dependencies"`; if it also has a `version`: `cider bump patch`, `cider version-sync`, `cider release` (same skip rules as `Updater._bumpVersion` / `_releaseVersion`). No report file, no flutter-compat logic.

- [ ] **Step 1: Write failing tests** — fixture: a temp pub workspace (root + `packages/a` pure Dart with `build_runner` dev dep and a trivial builder-free setup, `packages/b` with CHANGELOG + version). Tests (each with `timeout: Timeout(Duration(minutes: 5))`):
  - `application mode regenerates root lockfile when only a member pubspec changed` — bump a member constraint before calling; assert root `pubspec.lock` contains the new version (Review Focus 1).
  - `runs build_runner when only a member depends on it` — assert `.dart_tool/build` exists at the root (Review Focus 2).
  - `sdk-only upgrades add sdk changelog lines and one dependencies line` — assert `CHANGELOG.md` of `packages/b` contains `Updated min sdk version to ^3.13.0` and exactly one `Updated dependencies` (Review Focus 3).
  - `duplicate upgrades for one package produce one patch bump` — two entries for the same packageFile; assert version `1.0.0` → `1.0.1` (Review Focus 5).
  - `package without version or changelog is skipped`.
- [ ] **Step 2:** Run → FAIL.
- [ ] **Step 3:** Implement `PostUpgrade`, the `PubWrapper` changes and the move.
- [ ] **Step 4:** Run → PASS; analyze.
- [ ] **Step 5:** Stage.

---

### Task 4: CLIs `renovate-post-upgrade` and `renovate-config`; remove `auto-update` — ✅ DONE 2026-10-28

**Files:**
- Create: `bin/renovate_post_upgrade.dart`, `bin/renovate_config.dart`, `lib/src/renovate/global_config.dart`
- Modify: `pubspec.yaml` executables — remove `auto-update`, add `renovate-post-upgrade: renovate_post_upgrade` and `renovate-config: renovate_config`
- Delete: `bin/auto_update.dart` and what remains of `lib/src/auto_update/` after Task 3's move (`update_checker.dart`, `updater.dart`); the outdated models moved to `lib/src/pub/models/` stay — `GlobalConfig` uses them
- Test: `test/integration/renovate/global_config_test.dart`

**Interfaces:**
- `renovate-post-upgrade --mode application|library` (`args`, structure as the old `bin/auto_update.dart` incl. `Github.runZoned`, `--help`, FormatException handling). Calls `PostUpgrade(mode: …)(Directory.current, await UpgradeData.fromEnvironment())`. No other flags (they would need `allowedCommands` changes).
- `renovate-config --repository <dir> --[no-]flutter-compat --output <path>` writes the global config JSON. `<dir>` is the read-only checkout from Task 6 (it may be modified — it is thrown away).
- `class GlobalConfig({required final Directory repository, required final bool flutterCompat}) { Future<Map<String, dynamic>> build(); }` — returns exactly the global-config values from Global Constraints plus `packageRules` = workspace rule followed by resolvable caps (spec Component 1; reference: step "Compute package rules" of the spike workflow):
  - workspace rule: `{"description": "Workspace packages are resolved locally", "matchManagers": ["pub"], "matchPackageNames": <all names of PubWrapper.workspaceList()>, "enabled": false}`;
  - if `flutterCompat` and the root pubspec has no `flutter_test` dev dependency: `PubWrapper.addFlutterTest()` (isFlutter forced true);
  - `PubWrapper.outdated()` (extend it to pass `--show-all --dev-dependencies --no-dependency-overrides` if not already) and one `{"description": "Newest resolvable version is <v>", "matchManagers": ["pub"], "matchPackageNames": [<pkg>], "allowedVersions": "<=<v>"}` per direct/dev package whose resolvable version differs from latest (both non-null).

- [ ] **Step 1: Write failing tests** for `GlobalConfig.build` (temp pub workspace fixture like Task 3; network needed, `timeout: Timeout(Duration(minutes: 5))`): `contains fixed global values`, `workspace rule lists all workspace package names`, `caps test at the version allowed by flutter_test` (pure-Dart member with `test: ^1.25.0`, flutterCompat true → a rule for `test` whose allowedVersions equals `<=` the `test` version resolvable with the installed Flutter), `no flutter_test injected without flutterCompat` (pubspec unchanged on disk).
- [ ] **Step 2:** Run → FAIL.
- [ ] **Step 3:** Implement both bins, `GlobalConfig`, pubspec changes, deletions.
- [ ] **Step 4:** Run tests → PASS; `dart run bin/renovate_post_upgrade.dart --help` and `dart run bin/renovate_config.dart --repository <copy of the test repo> --output /dev/stdout` print sensible output (compare with the spike's config: caps for `test` and `build_runner`, workspace rule); analyze → no issues.
- [ ] **Step 5:** Stage.

---

### Task 4a: Follow-up spike — `GITHUB_TOKEN` instead of the App — ✅ DONE 2026-10-30

Added 2026-10-29. Re-verifies in `Skycoder42/renovate-test` what Task 0 proved with the App, plus the new finish flow. Results go into spec "Phase 0b". Nothing in dart_test_tools changes; the CLIs of Tasks 1–4 need no change for this switch.

Results (T1–T9 all ✅, no fallback needed) are recorded in spec "Phase 0b"; the steps below are kept for the record. Deviations: Step 5 made CI red via a repository variable `FAIL_CI` (no commits to main) and tested the old-SHA refusal by running `gh pr merge --match-head-commit <old SHA>` by hand after the Renovate rebase (an empty push would have cancelled the approved run via CI's `cancel-in-progress`); Step 6 needed no rebase (the variable is read at job runtime); Step 7 ticked the rebase checkbox of the application-preset dashboard instead of switching to the library preset (T9 only concerns the trigger; library behaviour is covered by S8).

**Prerequisites (user):** in the test repo enable *Allow GitHub Actions to create and approve pull requests*; uninstall the App from the test repo (so nothing silently falls back to it) and delete its secrets there; close/delete existing `renovate/*` PRs and branches.

**Files (test repo only):** `.github/workflows/renovate-spike.yml`, `.github/workflows/ci.yml`.

- [ ] **Step 1:** In `renovate-spike.yml` remove the App token step; job `permissions: {contents: write, pull-requests: write, issues: write, statuses: write}`; Renovate env `RENOVATE_TOKEN: ${{ github.token }}`, `RENOVATE_REVIEWERS: ${{ github.repository_owner }}`, `RENOVATE_GIT_AUTHOR: "github-actions[bot] <41898282+github-actions[bot]@users.noreply.github.com>"`. Ensure `ci.yml` has a `workflow_dispatch` trigger.
- [ ] **Step 2:** In `ci.yml` replace the notify job by a hand-written finish job (spec Component 4: same condition, `succeeded` from `needs.*.result`, `gh pr merge --squash --delete-branch --match-head-commit`, `gh workflow run ci.yml --ref main`, `gh pr comment` on failure).
- [ ] **Step 3:** Run with the application preset. Record T1 (PR/commit by `github-actions[bot]`, *Approve workflows to run* shown), T3 (review request push at PR open — user confirms), T4 (approve from GitHub Mobile possible? — user tries).
- [ ] **Step 4:** Run the spike workflow again without changes. Record T2 (same PR updated or untouched, no duplicate, dashboard updated).
- [ ] **Step 5:** Make CI fail on the Renovate branch (e.g. a temporary failing step in `ci.yml` on main, then let Renovate rebase), approve. Record T5 (comment + mention push) and T7 (the rebase push needed a new approval). Then, with a run approved, push an empty commit to the branch before CI ends and record that the merge with the old SHA is refused (T7).
- [ ] **Step 6:** Revert the failure, let Renovate rebase, approve. Record T6 (merged, branch deleted) and T8 (CI run on `main` started by `workflow_dispatch`, no approval needed).
- [ ] **Step 7:** Library preset branch: tick a dashboard checkbox. Record T9.
- [ ] **Step 8:** Write T1–T9 into spec "Phase 0b"; apply a fallback from there where needed and reflect it in Tasks 6/8; stop for user review.

---

### Task 5: Generator prerequisites — ✅ DONE 2026-10-30

**Files:**
- Modify: `tool/ci_gen/types/job.dart` — add `@JsonKey(includeIfNull: false) String? concurrency` (plain group string); regenerate freezed/json parts with `dart run build_runner build`
- Modify: `tool/ci_gen/common/tools.dart` — add `actionsCacheRestore` (`actions/cache/restore@v6`), `actionsCacheSave` (`actions/cache/save@v6`)
- Modify: `tool/ci_gen/common/inputs.dart` — add `renovateVersion` (string, default = the pinned version), and for Task 8 `succeeded` (boolean, required), `mergeMethod` (string, default `squash`; description lists `squash`/`merge`/`rebase`), `dispatchWorkflow` (string, optional, empty default = the calling workflow); reword `flutterCompat` description to "Whether Renovate must not propose dependency versions beyond the ones pinned by the Flutter SDK."; delete `validationWorkflow` only if nothing else uses it (check `update_actions`)
- No new secrets.

- [ ] **Step 1:** Implement; `dart run tool/ci_gen.dart` → existing workflows regenerate unchanged (`git diff --stat .github` is empty).
- [ ] **Step 2:** Analyze → no issues. Stage.

---

### Task 6: Reusable `renovate.yml` — ✅ DONE 2026-10-30

**Files:**
- Create: `tool/ci_gen/renovate/renovate_workflow.dart`, `tool/ci_gen/renovate/jobs/renovate_job_builder.dart`, `tool/ci_gen/renovate/steps/renovate_builder.dart` (pattern: `tool/ci_gen/auto_update/**`)
- Modify: `tool/ci_gen.dart` — register `RenovateWorkflow()`
- Modify: `tool/ci_gen/common/inputs.dart` — remove `reviewer` and `renovateVersion` (changed 2026-10-30, user request)
- Modify: `tool/ci_gen/common/steps/checkout_builder.dart` — add `sparseCheckout`
- Create: `tool/renovate/package.json` (`renovate` exact `44.198.0`, `engines.node: ^24.11.0`), `tool/renovate/package-lock.json`, `tool/renovate/.npmrc` (`registry=https://registry.npmjs.org/`)
- Modify: `.gitignore` (`node_modules/`), `.pubignore` (`/renovate/`, `/tool/renovate/` — anchored, an unanchored `renovate/` also drops `lib/src/renovate/`)
- Generated: `.github/workflows/renovate.yml`

**Interfaces:**
- Consumes: Task 5 tools/inputs/secrets/`Job.concurrency`; `FlutterSdkJobBuilderMixin`; `InstallToolsActionBuilder.step(withDartTestTools: true)`; `renovate-config` CLI (Task 4).
- Workflow name `renovate`; one job id `renovate`, name `Renovate`, `runsOn: ubuntu-latest`, `permissions: {contents: write, pull-requests: write, issues: write, statuses: write}`, `concurrency: renovate-${{ github.repository }}`.
- Steps in order (changed 2026-10-30: Renovate from the lockfile instead of `npx renovate@<input>`): Flutter SDK steps → install tools → sparse checkout of `Skycoder42/dart_test_tools` ref `main` (`tool/renovate/` only, path `dart_test_tools`, no credentials) → setup-node (`node-version-file: dart_test_tools/tool/renovate/package.json`, `cache: npm`, `cache-dependency-path: …/package-lock.json`) → `npm ci` in `dart_test_tools/tool/renovate` → `CheckoutBuilder` with `persistCredentials: false` and path `repo` → `renovate-config --repository repo $flutterCompatFlag --output "$RUNNER_TEMP/renovate-config.json"` (flag via `Functions.case$` like the old auto-update builder) → cache restore (`path: /tmp/renovate/cache/renovate/repository`, `key: renovate-cache-${{ github.run_id }}-${{ github.run_attempt }}`, `restore-keys: renovate-cache-`) → `node_modules/.bin/renovate` (working directory `dart_test_tools/tool/renovate`) with env `RENOVATE_TOKEN: ${{ github.token }}`, `RENOVATE_CONFIG_FILE`, `RENOVATE_REPOSITORIES: ${{ github.repository }}`, `RENOVATE_REPOSITORY_CACHE: enabled`, `RENOVATE_REVIEWERS: ${{ github.repository_owner }}`, `RENOVATE_GIT_AUTHOR: "github-actions[bot] <41898282+github-actions[bot]@users.noreply.github.com>"`, `LOG_LEVEL: info` (plus whatever fallback Task 4a needed) → cache save (`if: always()`). No App token step, no secrets.

- [ ] **Step 1:** Implement and register; `dart run tool/ci_gen.dart`.
- [ ] **Step 2:** Verify `.github/workflows/renovate.yml` with `yq` / `actionlint` if installed: one job, the four write permissions and nothing else, checkout with `persist-credentials: false`, `RENOVATE_TOKEN` is `github.token`, inputs `flutterSdkChannel`/`flutterCompat`, no `secrets:` block.
- [ ] **Step 3:** Analyze; stage.

---

### Task 6a: Post-upgrade ignores non-pub updates — ✅ DONE 2026-10-31

Added 2026-10-30: this repo's own Renovate also updates `tool/renovate/package.json` (npm), and all updates share one branch, so the data file can contain npm entries.

**Files:**
- Modify: `lib/src/renovate/models/renovate_upgrade.dart` (Task 1 model) — `RenovateUpgrade` gets `required String manager`; regenerate with `dart run build_runner build`
- Modify: `lib/src/renovate/post_upgrade.dart` (Task 3 runner) — drop entries with `manager != 'pub'` before root resolution; if none is left, return without running anything (no resolution, no changelog, no bump)
- Modify: the Task 1/3 tests under `test/integration/renovate/` — existing fixtures get `"manager": "pub"`

**Interfaces:**
- Produces: data file key `manager`, consumed by Task 7's `dataFileTemplate`.

- [ ] **Step 1:** Failing tests: (a) model parses `manager`; (b) data file with only an npm entry (`packageFile: tool/renovate/package.json`) → no command run, no file changed; (c) mixed pub + npm entries → pub package processed exactly as without the npm entry (one changelog entry, one bump). Run `dart test test/integration/renovate` → (a)–(c) fail.
- [ ] **Step 2:** Implement; `dart test test/integration/renovate` → all pass. Analyze. Stage.

---

### Task 7: Presets — ✅ DONE 2026-10-31

Deviations: the "(minor)"/"(major)"/"(patch)" title suffix is appended by Renovate to group PR titles (`workers/repository/updates/generate.js`, `compilePrTitle`) unless `prTitleStrict: true`; set on both breaking rules (`groupName: "breaking dependencies"`) and on the base "all" group (a 0.x patch with `separateMinorPatch` could otherwise add " (patch)" to the weekly library PR). Validation runs as repo config in strict mode: `renovate-config-validator --strict --no-global …` (without `--no-global` the files are validated as global config).

**Files:**
- Create: `renovate/base.json`, `renovate/library.json`, `renovate/application.json`

**Interfaces:**
- `library.json` and `application.json` extend `github>Skycoder42/dart_test_tools//renovate/base` (S5 was deferred — verified in Task 12).
- Contents exactly as the spike presets in `Skycoder42/renovate-test/spike-presets/` (spec Component 2), with two changes: (1) drop `skipArtifactsUpdate: true` from `base.json` (changed 2026-10-31, see spec Component 2 — Renovate's own lockfile update is harmless, and the post-upgrade CLI still resolves); (2) rename the library breaking group so the PR title reads well (spike title was "Update breaking updates (minor)"; e.g. `groupName: "breaking dependencies"`, and drop the "(minor)" suffix via the group's commit message topic/suffix options). `postUpgradeTasks` in each child preset (mode differs): `commands: ["renovate-post-upgrade --mode library"]` / `["renovate-post-upgrade --mode application"]`, `executionMode: "branch"`, `fileFilters: ["**/*"]`, `dataFileTemplate`:
  `[{{#each upgrades}}{"manager":"{{{manager}}}","depName":"{{{depName}}}","packageFile":"{{{packageFile}}}","depType":"{{{depType}}}","currentValue":"{{{currentValue}}}","newValue":"{{{newValue}}}","updateType":"{{{updateType}}}"}{{#unless @last}},{{/unless}}{{/each}}]`

- [ ] **Step 1:** Write the three files.
- [ ] **Step 2:** In `tool/renovate/`: `npm ci`, then `node_modules/.bin/renovate-config-validator --strict --no-global ../../renovate/base.json ../../renovate/library.json ../../renovate/application.json` (validator from the lockfile, same version as the workflow) → "Config validated successfully" for each.
- [ ] **Step 3:** Stage.

---

### Task 8: Reusable `renovate-finish.yml`

Replaces the former `notify.yml` task (changed 2026-10-29).

**Files:**
- Create: `tool/ci_gen/renovate_finish/renovate_finish_workflow.dart`, `tool/ci_gen/renovate_finish/jobs/renovate_finish_job_builder.dart`, `tool/ci_gen/renovate_finish/steps/renovate_finish_builder.dart`
- Modify: `tool/ci_gen.dart` — register `RenovateFinishWorkflow()`
- Generated: `.github/workflows/renovate-finish.yml`

**Interfaces:**
- Consumes: Task 5 inputs `succeeded`, `mergeMethod`, `dispatchWorkflow`.
- Job id `finish`, name `Finish Renovate PR`, `runsOn: ubuntu-latest`, `permissions: {contents: write, pull-requests: write, actions: write}`, `if:` `github.event_name == 'pull_request' && github.event.pull_request.user.login == 'github-actions[bot]' && startsWith(github.head_ref, 'renovate/') && github.event.pull_request.head.repo.full_name == github.repository`. No checkout.
- All steps `Step.run` with `GH_TOKEN: ${{ github.token }}`, `gh … --repo "$GITHUB_REPOSITORY"`, PR number / head SHA / default branch passed via `env` (never interpolated into the script):
  1. `id: merge`, `if: inputs.succeeded` — `gh pr merge "$PR" --"$MERGE_METHOD" --delete-branch --match-head-commit "$HEAD_SHA"`.
  2. `if: inputs.succeeded && steps.merge.outcome == 'success'` — `gh workflow run "$WORKFLOW" --ref "$DEFAULT_BRANCH"`; `$WORKFLOW` = `dispatchWorkflow` input or, if empty, the file name parsed from `github.workflow_ref` (`owner/repo/.github/workflows/<file>@<ref>` → `<file>`); `$DEFAULT_BRANCH` = `github.event.repository.default_branch`.
  3. `if: always() && (!inputs.succeeded || steps.merge.outcome == 'failure')` — `gh pr comment "$PR" --body "@$REVIEWER …"`: "CI failed" or "automatic merge failed" (two texts) + link `$GITHUB_SERVER_URL/$GITHUB_REPOSITORY/actions/runs/$GITHUB_RUN_ID`. `$REVIEWER` = `github.repository_owner`.
  The job fails if step 1 or 2 failed (step 3 runs first), so the run stays red.

- [ ] **Step 1:** Implement, register, regenerate.
- [ ] **Step 2:** Verify the generated YAML: if-condition, the three permissions, inputs, no `${{ }}` inside `run:` scripts except via `env`; `actionlint` if installed. Analyze. Stage.

---

### Task 9: Remove auto-update, migrate this repo

**Files:**
- Delete: `tool/ci_gen/auto_update/`, `.github/workflows/auto-update.yml`, `.github/workflows/dart_test_tools_auto_update.yml`
- Modify: `tool/ci_gen.dart` (drop `AutoUpdateWorkflow`)
- Create: `.github/workflows/dart_test_tools_renovate.yml` (hand-written caller: `schedule: cron "15 3 * * 1"`, `workflow_dispatch`, `issues: types [edited]`; job `if: github.event_name != 'issues' || (github.event.issue.title == 'Dependency Dashboard' && !endsWith(github.actor, '[bot]'))`; `uses: Skycoder42/dart_test_tools/.github/workflows/renovate.yml@main` like the other callers; `permissions: {contents: write, pull-requests: write, issues: write, statuses: write}`; no secrets)
- Create: `renovate.json` → extends `github>Skycoder42/dart_test_tools//renovate/library`, plus (added 2026-10-30, Renovate updates itself): `enabledManagers: ["pub", "npm"]`; a rule `matchManagers: ["npm"], matchFileNames: ["!tool/renovate/package.json"], enabled: false` (npm only for that file); no `skipArtifactsUpdate` setting needed (the presets leave artifact updates on since 2026-10-31, so Renovate updates `package-lock.json` itself); a rule `matchPackageNames: ["renovate"], minimumReleaseAge: "3 days"`; a rule `matchManagers: ["npm"], matchDepTypes: ["engines"], enabled: false` (Node raised by hand when a Renovate major needs it)
- Modify: `.github/workflows/dart_test_tools_ci.yml` — add job `renovate` (`needs: [ci]`, `if: ${{ !cancelled() && github.event_name == 'pull_request' }}`, `uses: …/renovate-finish.yml@main`, `permissions: {contents: write, pull-requests: write, actions: write}`, `with: succeeded: ${{ !contains(needs.*.result, 'failure') && !contains(needs.*.result, 'cancelled') }}`). The CI already has `workflow_dispatch`, so the dispatch after a merge runs CI + the `cd` job on `main`.
- Modify: `.github/dependabot.yml` — remove the `pub` entry
- User (repo settings, not code): enable *Allow GitHub Actions to create and approve pull requests* for dart_test_tools.

- [ ] **Step 1:** Apply; `dart run tool/ci_gen.dart`; `grep -rn "auto-update\|auto_update\|AutoUpdate" --exclude-dir=.dart_tool --exclude-dir=.git --exclude-dir=docs .` only hits `CHANGELOG.md` history and files handled in Task 10.
- [ ] **Step 2:** Validate `renovate.json` with the validator command from Task 7. Analyze. Stage.

---

### Task 10: Repair skill and docs

**Files:**
- Delete: `skills/dart-test-tools-auto-update/`
- Create: `skills/dart-test-tools-renovate-fix/SKILL.md`, `skills/dart-test-tools-renovate-fix/scripts/prepare-fix.sh`
- Modify: `skills/dart-test-tools-native-update/SKILL.md`, `skills/dart-test-tools-native-update/scripts/native-update.sh`, `skills/dart-test-tools-cli-help/SKILL.md`, `README.md`

**Interfaces / content:**
- Skill frontmatter description: "Use when a Renovate dependency-update PR of a dart or flutter package is red, or the user wants to reproduce or repair it locally." Flow: find the open Renovate PR (`gh pr list --author 'app/github-actions'` and branch prefix `renovate/`), check it out, re-run `renovate-post-upgrade --mode <mode from renovate.json preset>` with a data file built from the PR's diff of pubspec files, validate in CI order (analyze → format → publish dry-run → unit tests; reuse the ordering and test-input discovery of the old skill's `SKILL.md:157-245` / `prepare-update.sh:269-271`, now reading `dart.yml`/`flutter.yml` callers), fix, push (notes for the user: Renovate then treats the branch as edited until "rebase" is ticked; a push by the user starts CI without approval, and the finish job merges the PR once CI is green, because it checks the PR author, not the pusher), and keep the old skill's offer to run `dart-test-tools-native-update` when the Flutter minor moved.
- README: replace the auto-update skill row; new section "Dependency updates with Renovate" with the consumer migration steps from spec Component 5 (repo setting *Allow GitHub Actions to create and approve pull requests*, caller workflow snippet identical in shape to `dart_test_tools_renovate.yml` incl. permissions, `renovate.json`, finish job + `workflow_dispatch` trigger in CI, dependabot change, recommended rulesets without required approvals) and the day-to-day flow (review request → check diff → *Approve workflows to run* → merged and released on green / comment on red; Renovate does not rebase when the default branch moves (`rebaseWhen=conflicted`, spec Phase 0b) — after a fix lands on the default branch, tick the PR's rebase checkbox and run the caller (or wait for the schedule), then approve again; a Dependency Dashboard left over from an earlier Renovate identity is not reused, close it by hand). Subsection "Customising" (added 2026-10-31, spec Component 5): own `packageRules` in `renovate.json` are applied after the preset's and are fine for ignoring/pinning/delaying packages or splitting pub packages into own groups; caveats: (a) other managers enabled by the consumer land in the shared `renovate/all` branch, the post-upgrade CLI ignores their entries (no changelog/bump for a non-pub-only branch); (b) own `postUpgradeTasks` are refused — the global config from `renovate-config` only allows `renovate-post-upgrade`; (c) don't set `automerge` (the finish job merges), `schedule` (the caller's cron decides, both together can make runs no-ops) or `reviewers` (set by the workflow); (d) don't add rules matching the `dart-version`/`flutter-version` datasources that change `versioning`, `allowedVersions` or `overrideDatasource` (would bring back Dart patch versions never shipped in Flutter or bare-version SDK constraints); (e) every pub group PR gets its own patch bump, so after one merges the others conflict on `CHANGELOG.md`/version, Renovate rebuilds them and they need a new approval. Remove any leftover mention of a GitHub App or `notify.yml`.

- [ ] **Step 1:** Write/modify; check every reference with `grep -rn "dart-test-tools-auto-update\|prepare-update.sh" .` → none left.
- [ ] **Step 2:** Run `bash -n skills/dart-test-tools-renovate-fix/scripts/prepare-fix.sh` → no syntax errors. Stage.

---

### Task 11: Changelog and major version

- [ ] **Step 1:** `dart run bin/cider.dart log removed 'auto-update workflow, auto-update CLI and dart-test-tools-auto-update skill'`; `log added` entries for: reusable `renovate.yml`, `renovate-finish.yml`, Renovate presets, `renovate-post-upgrade` and `renovate-config` CLIs, `dart-test-tools-renovate-fix` skill.
- [ ] **Step 2:** `dart run bin/cider.dart bump major` → version `8.0.0`; `dart run bin/cider.dart release`.
- [ ] **Step 3:** `dart run tool/ci_gen.dart` (install-tools now installs `^8.0.0`); run the full test suite `dart test test/integration` → all pass; analyze whole repo → no issues. Stage.

---

### Task 12: End-to-end verification in the test repo

- [ ] **Step 1:** Push the branch to dart_test_tools (user approval needed — outward-facing). In the test repo, replace the spike files with the real setup from the README, pointing `@main` references and preset refs at the feature branch. The generated `renovate.yml` checks out `Skycoder42/dart_test_tools` at `ref: main`, where `tool/renovate/package.json` does not exist yet: on the pushed branch, temporarily point that ref at the feature branch and revert it before merging.
- [ ] **Step 2:** Run the caller via `workflow_dispatch` with the application preset. Expected: one Renovate PR by `github-actions[bot]` whose single commit contains pubspec changes, root `pubspec.lock`, formatted/fixed code, changelog + patch bump; the owner gets a review-request push at PR open (user confirms); CI waits for *Approve workflows to run*; after approval and green CI the PR is merged with the approved SHA, the branch deleted, and a CI run on `main` is dispatched — of the *caller's* CI file, which confirms that `github.workflow_ref` inside the reusable `renovate-finish.yml` names the caller (not covered by Task 4a, whose finish job was hand-written in the caller). Also record S5 (presets fetched via `github>` with `GITHUB_TOKEN`; the Task 0 fallback "install the App on dart_test_tools" no longer applies — if it fails, back to the user).
- [ ] **Step 3:** Make CI red once (as in Task 4a Step 5): the owner gets the mention comment, nothing is merged.
- [ ] **Step 4:** Repeat Step 2 with the library preset (dashboard approval for majors, no lockfile committed).
- [ ] **Step 4a:** Self-update (after the merge to `main`, on dart_test_tools itself): run `dart_test_tools_renovate.yml`; once a `renovate` release newer than the pin is older than the minimum release age, the PR bumps `tool/renovate/package.json` and `tool/renovate/package-lock.json` together, the post-upgrade CLI ignores the npm entry (Task 6a), and nothing else in the PR comes from it.
- [ ] **Step 5:** Report results to the user; on approval, the user decides about committing (spec + plan + implementation together) and merging.
