# Renovate-based dependency updates — design

Date: 2026-10-27 · Status: draft for approval

## Intent

`dart_test_tools` ships a reusable `auto-update.yml` workflow plus an `auto-update` CLI that
upgrades dependencies and SDK constraints, runs build_runner/format/fix, bumps the version via
cider and opens a validated PR. We replace that whole mechanism with **self-hosted Renovate**,
still shipped as reusable building blocks from this repo:

- Renovate decides *what* to update (deps and SDK constraints), driven by shared presets.
- A `postUpgradeTasks` command (a new CLI of this package) performs the extra steps that
  auto-update does today, *inside* Renovate, so the fixups land in the same commit as the update.
- Renovate runs with the job's own `GITHUB_TOKEN`, so its PR's CI runs wait for the owner's
  approval; the owner is notified when the PR opens.
- The consumer's normal CI validates the PR; a reusable finish workflow at the end of CI merges
  the PR when it is green, or comments with a mention when it is red.

Why Renovate instead of Dependabot (researched, see "Background"): Dependabot cannot update
`environment.sdk`/`flutter`, cannot raise lower bounds of in-range deps for libraries, and its
PRs run in a restricted Actions context, which makes fixup pushes and CI re-runs awkward.

## Goals

1. Two shared presets, picked per repo with one line in `renovate.json`:
   - **application** (lockfile committed): all updates incl. majors, deps and SDK.
   - **library** (no lockfile): minor/patch only, but lower bounds are raised (`rangeStrategy: bump`);
     same for SDK constraints.
2. Weekly, everything grouped into **one** PR per repo.
3. Pub **workspaces** fully supported (root lockfile kept in sync).
4. Fixup steps inside Renovate: lockfile resolution, analyzer plugin pin sync, build_runner,
   `dart format`, `dart fix --apply`, cider changelog + patch bump + version-sync + release.
5. No credential that reaches beyond one repository: Renovate uses the job's `GITHUB_TOKEN`.
6. Human gate before CI: the owner gets a GitHub Mobile push when the PR is opened (review
   request), looks at the diff and approves the workflow runs. Every new push to the PR branch
   needs a new approval (GitHub behaviour for `GITHUB_TOKEN`-created PR events since 2026-06).
7. After CI on a Renovate PR finishes (not cancelled):
   - success → the PR is merged (pinned to the approved head commit), the branch deleted, and the
     calling CI workflow is dispatched on the default branch so the usual release chain runs;
   - failure (or a failed merge) → a PR comment mentioning the owner.
8. Everything consumable the same way as today: reusable workflows `@main` + small caller files.

## Non-goals

- Security alerts/updates: stay with Dependabot (repo settings). Renovate's vulnerability
  features are disabled (they don't support pub anyway).
- GitHub Actions version updates: stay with Dependabot (`github-actions` ecosystem) / the
  existing `update-actions` workflow. Renovate only runs the `pub` manager.
- Renovate's own `automerge` (merging happens in the finish workflow, after the owner approved
  the runs).
- Notifications for PRs other than Renovate's (the former `notify.yml` idea is dropped).
- A central Renovate runner that processes all repos (decided: per-repo).

## Anti-goals

- Fixup commits pushed on top of Renovate's commit (causes edited-branch detection, extra CI
  runs, stale-SHA checks). All changes go into Renovate's single commit.
- The Renovate job holding any secret, or a token with `workflows` permission.
- Credentials shared across repositories (GitHub App private key, PAT): one leaked copy would
  open every repository they cover.
- Merging a commit the owner has not approved (the merge is pinned to the head commit whose CI
  run was approved).
- Weekly PRs that are red by construction (e.g. proposing versions newer than Flutter pins).

## Decisions made by the user

- Self-hosted Renovate with `postUpgradeTasks` (not the Mend-hosted app, not Dependabot).
- Per-repo runner: reusable workflow + caller in each consumer repo.
- Authentication: the job's `GITHUB_TOKEN` (changed 2026-10-29; previously a GitHub App — its
  private key would sit in every consumer repo's secrets and mint tokens for all of them).
- Flow: review request at PR open → owner approves the workflow runs → CI → automatic merge
  on success, comment with mention on failure (decided 2026-10-29).
- Two presets (application / library); SDK updates follow the same application/library split.
- Pub workspaces are a hard requirement.
- Every Renovate PR does cider changelog + patch bump + release (as today).
- Remove `auto-update.yml`, the `auto-update` CLI and the `dart-test-tools-auto-update` skill
  (released as a new major version of dart_test_tools).
- Merge/comment = a job at the end of the CI run, Renovate PRs only, as a reusable workflow.
- Dependabot keeps security alerts.
- Removal happens in the same change; consumers keep calling `@main` and will break until
  migrated — accepted. The user migrates their consumer repos by hand, guided by the README.
- Library preset: **every** major needs dashboard approval, dev_dependencies included.
- The `dart-test-tools-auto-update` skill is replaced by a rewritten skill for repairing a red
  Renovate PR (not just deleted).
- Work starts with a throwaway spike in a test repo; the real build follows on proven config.

## Architecture

```
consumer repo                                 dart_test_tools
─────────────                                 ───────────────
.github/workflows/renovate.yml  ──uses──▶  .github/workflows/renovate.yml (generated)
  (cron weekly, dispatch,                     1. Flutter SDK (subosito, channel input)
   dashboard "issues: edited")                2. install dart_test_tools CLI (trusted, pre-Renovate)
                                              3. node + Renovate from tool/renovate/package-lock.json
                                                 (`npm ci`, binarySource=global)
renovate.json                                    with RENOVATE_TOKEN = GITHUB_TOKEN
  extends github>…//renovate/<preset>  ◀──    renovate/{base,library,application}.json
                                              postUpgradeTask → `renovate-post-upgrade` CLI
Renovate PR (by github-actions[bot], owner requested as reviewer ⇒ mobile push)
  └─ owner approves the workflow runs
     └─ pull_request ▶ consumer CI (unchanged)
                        └─ last job ──uses──▶  .github/workflows/renovate-finish.yml (generated)
                                                 green: merge @ approved SHA, delete branch,
                                                        dispatch CI on default branch (→ release)
                                                 red:   comment mentioning the owner
```

## Component 1 — reusable workflow `renovate.yml` (generated)

New generator under `tool/ci_gen/renovate/`, registered in `tool/ci_gen.dart`. One job,
`runs-on: ubuntu-latest`, `permissions: {contents: write, pull-requests: write, issues: write,
statuses: write}` (Renovate's token; the caller must grant the same), job-level
`concurrency: renovate-${{ github.repository }}` without cancel-in-progress.

Inputs (names follow existing conventions in `tool/ci_gen/common/inputs.dart`):
- `flutterSdkChannel` (default `stable`) — the SDK Renovate's tasks run with.
- `flutterCompat` (bool, default `true`) — see "Resolvable caps" below.

No secrets. The Renovate version is no input (changed 2026-10-30): it is pinned in this repo by
`tool/renovate/package.json` (exact version ≥ 44.164.5; earlier versions don't pass `constraints`
to branch-mode tasks) and `tool/renovate/package-lock.json` (whole dependency tree with integrity
hashes). `tool/renovate/.npmrc` pins the public npm registry so the lockfile
never points at a private one. This repo's own Renovate updates both (see "Removal and
migration in this repo"), so Renovate keeps itself up to date; consumers get a new version as
soon as it is merged to `main`, like every other change to the workflow or the presets.

Steps:
1. Flutter via the existing `FlutterSdkJobBuilderMixin` (subosito), so `flutter` and `dart` on
   PATH are the exact SDK CI uses.
2. Install the dart_test_tools CLI via the existing `install-tools` composite action (must
   happen *before* Renovate runs — it is the trusted code).
3. Sparse checkout of `Skycoder42/dart_test_tools@main` (`tool/renovate/` only, no credentials),
   `actions/setup-node` with `node-version-file: …/tool/renovate/package.json` (`engines.node`,
   Renovate 44 needs `^24.11.0`) and the npm cache keyed on the lockfile, then `npm ci`.
   `main` is hardcoded like the `install-tools@main` reference: a reusable workflow cannot
   reliably see the ref it was called with.
4. `actions/checkout` with `persist-credentials: false` into a subdirectory — a read-only copy
   used only to compute package rules (step 5). Renovate still clones the repo itself.
5. Write the Renovate **global config** to `$RUNNER_TEMP` (see below), restore the repository
   cache (`/tmp/renovate/cache/renovate/repository`, key per run, restore-key prefix).
6. `node_modules/.bin/renovate` (from step 3) with `RENOVATE_TOKEN: ${{ github.token }}`,
   `RENOVATE_CONFIG_FILE`, `RENOVATE_REPOSITORIES=${{ github.repository }}`,
   `RENOVATE_REVIEWERS` (`github.repository_owner`) and `RENOVATE_GIT_AUTHOR` set to
   `github-actions[bot] <41898282+github-actions[bot]@users.noreply.github.com>`. The reviewer is
   set here, not in the presets, because the owner differs per repo.
7. Save the repository cache.

Repository setting required: *Allow GitHub Actions to create and approve pull requests*
(otherwise Renovate cannot open the PR with `GITHUB_TOKEN`).

Global config (written by the workflow, not overridable by repos):
- `platform: github`, `onboarding: false`, `requireConfig: "required"` (repos opt in via
  `renovate.json`), `binarySource: "global"`, `repositoryCache: "enabled"`,
  `executionTimeout` raised (≥ 30 min, for build_runner).
- `allowedCommands`: anchored regexes allowing **only** the `renovate-post-upgrade` CLI with its
  known flags.
- `customEnvVariables`: `PUB_CACHE` if non-default (Renovate only passes HOME/PATH/locale to
  child processes), plus anything else the CLI turns out to need.
- **Resolvable caps** (decided by the user after the spike): in the checkout, temporarily add
  `flutter_test` (sdk) as dev dependency of the root pubspec when `flutterCompat` is true and it
  is missing, run `flutter pub get` and `flutter pub outdated --json --show-all
  --dev-dependencies --no-dependency-overrides`, and emit one global packageRule
  `{matchManagers: ["pub"], matchPackageNames: [pkg], allowedVersions: "<=<resolvable>"}` for
  every direct/dev dependency whose resolvable version is below the latest. Renovate then only
  proposes versions pub can resolve together, including versions blocked *indirectly* by
  Flutter SDK pins (e.g. `test` via `test_api`), so the PR text always matches the commit.
  This replaces both the old `flutter_test` trick and per-package Flutter pin rules. `pub
  outdated` only resolves, it runs no package code.
- **Workspace packages**: one global packageRule `{matchManagers: ["pub"], matchPackageNames:
  [<all names from pub workspace list>], enabled: false}` so workspace-internal deps
  (`pure: ^1.0.0` without `path:`) are never looked up on pub.dev, where an unrelated package
  of the same name may exist.
- Both are computed by the `renovate-config` CLI from the checkout.

## Component 2 — Renovate presets (hand-written JSON in this repo)

Location: `renovate/base.json`, `renovate/library.json`, `renovate/application.json`.
Consumers use `{"extends": ["github>Skycoder42/dart_test_tools//renovate/library"]}` (or
`application`), optionally pinned with `#<tag>`.

**base** (research-verified unless marked):
- `enabledManagers: ["pub"]`; `vulnerabilityAlerts.enabled: false`; dependency dashboard on;
  `prHourlyLimit: 0`; no Renovate `schedule` (the caller's cron decides); no `reviewers`
  (the owner differs per repo — the workflow sets them, Component 1); `automerge` stays off
  (Component 4 merges).
- `rangeStrategy: "bump"`.
- No `skipArtifactsUpdate` (changed 2026-10-31; the spike presets set it `true`). Renovate's pub
  artifact updater (checked in 44.198.0, `manager/pub/artifacts.js`) only handles a
  `pubspec.yaml` with a sibling `pubspec.lock` (workspace members and library repos without a
  committed lockfile are skipped) and runs `dart`/`flutter pub upgrade <deps>` there, choosing
  `flutter` only if that pubspec contains `sdk: flutter`. A Dart workspace root with Flutter
  members resolves fine with `dart` as long as the Flutter SDK is installed (tested by the user),
  so this is harmless; the post-upgrade CLI still does the full resolution afterwards. Leaving it
  on lets other managers (e.g. npm in this repo) update their lockfiles.
- Grouping into one branch: rule `{matchPackageNames: ["*"], groupName: "all dependencies",
  groupSlug: "all", group: {branchTopic: "all"}}` (the `branchTopic` collapses the
  major/minor buckets into one branch — verified in lookup mode).
- SDK constraints: rule for `matchDatasources: ["dart-version", "flutter-version"]` with
  `versioning: "npm"` (**mandatory** — without it, current Renovate rewrites `^3.6.0` to a bare
  `3.13.7` and skips `>=` flutter constraints) and `allowedVersions: "/^\\d+\\.\\d+\\.0$/"`
  (constraints stay `^x.y.0` / `>=x.y.0`).
- Dart SDK only offered in versions shipped by Flutter stable: a `customDatasources`
  entry `flutter-dart` over Flutter's `releases_linux.json` (stable, `dart_sdk_version`,
  earliest release date) + `overrideDatasource: "custom.flutter-dart"` for dep `dart` (must be
  the last rule matching `dart-version`). Avoids bumping `sdk` to Dart patches that never
  shipped in Flutter.
- `postUpgradeTasks`: `{commands: ["renovate-post-upgrade --mode <set by child preset>"],
  executionMode: "branch", fileFilters: ["**/*"], dataFileTemplate: <JSON list of upgrades:
  depName, packageFile, depType, currentValue, newValue, updateType>}` (exact template:
  `spike-presets/application.json` in the test repo).
- `minimumReleaseAge: "3 days"` for `matchManagers: ["pub"]` (added 2026-10-31, user request).
  Renovate's default `minimumReleaseAgeBehaviour: "timestamp-required"` holds updates without a
  release timestamp forever; all pub datasources in use have one: `dart` (pub.dev `published`),
  `flutter-version` (`release_date`) and `custom.flutter-dart` (earliest Flutter release date,
  all 107 entries checked) — plain `dart-version` has none, but `dart` is always overridden.
  Too-young versions get no branch (`internalChecksFilter: "strict"`) and show as pending in the
  dashboard. Packages from third-party pub hosts without `published` would be held forever.

**library** = base +
- Majors (deps, dev_dependencies *and* SDK — decided by the user): `dependencyDashboardApproval:
  true` instead of a PR — visible in the dashboard, opt-in via checkbox. *(Approval rather than
  `enabled: false` is my call; otherwise majors would be invisible.)*
- 0.x deps: minors are breaking in pub → `separateMinorPatch: true` scoped via
  `matchCurrentValue: "/^(\\^|~|>=)?\\s*0\\./"`, then minor updates with
  `matchCurrentVersion: "<1.0.0"` also behind dashboard approval. Keeps 0.x patches flowing.
- Approved majors / 0.x minors go to a **separate branch/PR** (own `groupSlug`/`branchTopic`,
  e.g. `breaking`), so a pending approval never holds back the weekly "all" PR. *(My call.)*
- Keep `separateMajorMinor: true` (default). Do **not** extend `group:all` (its
  `separateMajorMinor: false` drops non-latest updates once majors are disabled).
- Post-upgrade mode: `library` (resolve with `pub get`, lockfile not committed).

**application** = base +
- `separateMajorMinor: false` (one update per dep, the latest, majors included).
- Post-upgrade mode: `application` (resolve with `pub upgrade` at the root → also refreshes
  transitive deps, replacing Renovate's separate lockFileMaintenance PR).

## Component 3 — `renovate-post-upgrade` CLI (replaces `auto-update`)

New executable in `pubspec.yaml`, built by refactoring `lib/src/auto_update/` (reuse
`pub_wrapper.dart`, the workspace iteration of `sdk_iterator.dart`, and the analyzer-plugin,
auto-fix and cider parts of `updater.dart`; drop `update_checker.dart` and SDK-constraint
editing — Renovate does that now).

Input: `--mode application|library`, plus the Renovate data file at
`$RENOVATE_POST_UPGRADE_COMMAND_DATA_FILE` and env from `customEnvVariables`. Runs with cwd =
repo root.

Steps:
0. Ignore every data file entry whose `manager` is not `pub` (added 2026-10-30: this repo's own
   Renovate also updates `tool/renovate/package.json`, and all updates share one branch). If no
   entry is left, exit 0 without touching anything.
1. Determine the pub roots to process from the data file's `packageFile` entries (walk up to
   the workspace root for `resolution: workspace` members; deduplicate). No `workingDirectory`
   input needed.
2. Resolve at each root: `pub get` (library) / `pub upgrade` (application), using `flutter` if
   any package in the workspace needs the Flutter SDK, else `dart` (existing `pub_wrapper`
   logic, but evaluated across the whole workspace, not just the root pubspec).
3. Sync analyzer plugin pins in `analysis_options.yaml` (existing logic).
4. If `build_runner` is a dependency: `dart run build_runner build --workspace`
   (`--delete-conflicting-outputs`).
5. `dart format .`, `dart fix --apply`, `dart format .`.
6. Per package with a `version` and `CHANGELOG.md` (not a workspace root; same selection as
   today): cider `log changed "Updated dependencies"`, plus an entry per SDK constraint change
   found in the data file (dep `dart` / `flutter`), `bump patch`, `version-sync`, `release`.

Exit non-zero on failure → Renovate records an artifact error on the PR (the PR is still
created, CI will be red, the owner is notified). Tasks re-run on every Renovate rebase, so the
CLI must be deterministic on a fresh checkout of the base branch (it is, since Renovate always
rebuilds the branch from base).

## Component 4 — reusable workflow `renovate-finish.yml` (generated)

New generator under `tool/ci_gen/renovate_finish/`. Called by consumers as the last job of
their CI:

```yaml
renovate:
  needs: [ci, …]
  if: ${{ !cancelled() && github.event_name == 'pull_request' }}
  uses: Skycoder42/dart_test_tools/.github/workflows/renovate-finish.yml@main
  permissions:
    contents: write
    pull-requests: write
    actions: write
  with:
    succeeded: ${{ !contains(needs.*.result, 'failure') && !contains(needs.*.result, 'cancelled') }}
```

Inputs: `succeeded` (bool, required — a reusable workflow cannot see the caller's `needs`),
`mergeMethod` (`squash` | `merge` |
`rebase`, default `squash`), `dispatchWorkflow` (default: empty = the calling workflow, taken
from `github.workflow_ref`, which points at the caller inside a reusable workflow).

Job condition — only Renovate's own PRs:
`github.event.pull_request.user.login == 'github-actions[bot]' &&
startsWith(github.head_ref, 'renovate/') &&
github.event.pull_request.head.repo.full_name == github.repository`.
Everything else (human PRs, Dependabot, update-actions PRs) skips the job.

Behaviour, all with `GH_TOKEN: ${{ github.token }}` and `--repo $GITHUB_REPOSITORY` (no
checkout):
- `succeeded` true →
  1. `gh pr merge <n> --<mergeMethod> --delete-branch --match-head-commit
     ${{ github.event.pull_request.head.sha }}`. Pinning the SHA guarantees only the commit
     whose CI run the owner approved is merged; if Renovate pushed in between, GitHub refuses.
  2. `gh workflow run <dispatchWorkflow> --ref <default branch>`. A merge done with
     `GITHUB_TOKEN` triggers no `push` workflow, so without this the release chain (CI on the
     default branch → `release.yml` → CD dispatch) would never run. `workflow_dispatch` is one
     of the two events `GITHUB_TOKEN` may trigger. The caller workflow therefore needs a
     `workflow_dispatch` trigger.
- `succeeded` false, or step 1 failed →
  `gh pr comment <n> --body "@<repository owner> <what failed>: <run URL>"`. A failed step 2 only fails
  the job (the PR is already merged; re-dispatch by hand).

Branch protection: required status checks are fine. A ruleset requiring ≥ 1 approving review
blocks the merge unless the owner also approves the PR itself (not just the runs) — document it.

## Component 5 — consumer setup (documented in README)

- Repository setting *Allow GitHub Actions to create and approve pull requests*.
- Caller workflow: `schedule` weekly, `workflow_dispatch`, and `issues: [edited]` guarded by
  `issue.title == 'Dependency Dashboard' && !endsWith(github.actor, '[bot]')` so dashboard
  checkboxes act immediately (Renovate's own dashboard edits trigger nothing anyway, since
  they are made with `GITHUB_TOKEN`; the guard stays as a cheap safety net). Job
  permissions: contents, pull-requests, issues, statuses write.
- `renovate.json` with the chosen preset.
- Finish job appended to CI; CI must have a `workflow_dispatch` trigger.
- `dependabot.yml`: remove the `pub` entry (keep `github-actions`). Security alerts remain in
  repo settings.
- Recommended hardening (document, not enforced): ruleset on the default branch requiring PRs
  and status checks (no required approvals, see Component 4), tag ruleset on release tags,
  environment approval for publish workflows.
- Customising (added 2026-10-31): own `packageRules` come after the preset's. Fine for
  ignoring, pinning, delaying or regrouping pub packages. Caveats to document: other managers
  join the `renovate/all` branch and are ignored by the post-upgrade CLI; own `postUpgradeTasks`
  are refused by `allowedCommands`; no `automerge` / `schedule` / `reviewers`; no rules on the
  SDK datasources that change `versioning`, `allowedVersions` or `overrideDatasource`; several
  pub groups each bump the version, so later PRs conflict, get rebuilt and need a new approval.
- How to use it: open the PR from the review request, check the diff, *Approve workflows to
  run*; green → merged and released automatically; red → comment, fix with the repair skill.

## Removal and migration in this repo

- Delete `AutoUpdateWorkflow` (+ `tool/ci_gen/auto_update/`), `.github/workflows/auto-update.yml`,
  `bin/auto_update.dart`, the `auto-update` executable entry and unused `lib/src/auto_update/`
  parts — all in this change (consumers break until migrated; accepted).
- Replace `skills/dart-test-tools-auto-update/` with a new skill for repairing a red Renovate
  PR: check out the Renovate branch, re-run the `renovate-post-upgrade` steps locally, validate
  the way CI does (analyze, format, publish dry-run, tests), help fix, and keep the existing
  offer to run the native update after a Flutter minor release. Update the README skill table
  and references in `skills/dart-test-tools-native-update/`.
- README: a migration section for consumer repos (replace the auto-update caller, add
  `renovate.json`, repo setting, finish job + `workflow_dispatch` in CI, drop pub from
  `dependabot.yml`).
- Keep `create-validated-pr` (still used by `update-actions`).
- Update `install-tools` so it installs the new major version of dart_test_tools.
- Replace `.github/workflows/dart_test_tools_auto_update.yml` with a Renovate caller; add
  `renovate.json` (library preset — this repo's `pubspec.lock` is gitignored); add the finish
  job to `dart_test_tools_ci.yml` (it already has `workflow_dispatch`); drop the `pub` entry from
  `.github/dependabot.yml`; enable the Actions PR setting (user, repo settings).
- This repo's `renovate.json` additionally lets Renovate update itself: the `npm` manager is
  enabled (for any npm package, not only `tool/renovate/package.json`, changed 2026-10-31), with the lockfile updated by Renovate (artifact
  updates are on, see Component 2), a minimum release age of
  a few days for `renovate` (pub updates get theirs from the base preset). `engines.node` (the Node the workflow runs on): minor/patch
  updates in the weekly PR (wanted, although the range already floats within its major); majors only to even (LTS) releases, in
  their own `node` group after dependency dashboard approval (changed 2026-10-31, was: no
  updates at all, raised by hand).
- Changelog + major version bump via `dart run bin/cider.dart` only (CLAUDE.md).

## Security model

Why `GITHUB_TOKEN` instead of a GitHub App: an App's private key belongs to the App, not to a
repo. Every consumer repo would hold a copy in its secrets, and whoever reads it from any one
repo (anyone with write access can add a workflow on a branch that reads a secret) can mint
tokens for **all** repos the App is installed on — with contents write, and App-token pushes do
trigger workflows (releases). `GITHUB_TOKEN` exists only for one job in one repo; nothing
long-lived is stored anywhere.

Renovate exposes its token to `postUpgradeTasks` (via `GIT_CONFIG_*` env and the clone's
`.git/config`); it cannot be unset. build_runner and `dart fix` execute dependency code, so a
malicious dependency could use that token. Accepted, with limits: token scoped to one repo,
valid only until the job ends, no `workflows` permission (`GITHUB_TOKEN` can never get it), no
secrets in the job, and pushes made with it trigger no workflows. Default-branch ruleset
recommended so it cannot push to the default branch directly. The same code already runs in CI
and locally. The job-level token now has write permissions for the whole job, so the actions in
it (subosito, setup-node, install-tools, cache) see a write token where they used to see a
read-only one; they are the same pinned actions CI uses. Renovate itself and its whole npm
dependency tree come from the committed lockfile (`npm ci`, integrity hashes), so a newly
published, compromised transitive package cannot reach the write token; updates of the lockfile
go through a reviewed Renovate PR in this repo (with a minimum release age).

The owner sees every Renovate commit before any CI run starts (approval per push), and the
finish workflow merges only that exact commit (`--match-head-commit`). It acts only on PRs
opened by `github-actions[bot]` from a `renovate/` branch of the same repo; someone able to fake
that already has write access.

## Phase 0 — spike (done 2026-10-28)

Ran in `Skycoder42/renovate-test` (pub workspace: `packages/pure` pure Dart with build_runner,
`packages/app` Flutter depending on `pure: ^1.0.0` by version only) with App
`skycoder42-renovate`, Renovate 44.190.2, a hand-written workflow, the presets of Component 2
as `local>` presets and a bash stand-in for the CLI. The working spike files in that repo
(`.github/workflows/renovate-spike.yml`, `spike-presets/*.json`, `spike/post-upgrade.sh`,
`.github/workflows/ci.yml`) are the reference for the real implementation.

| # | Item | Result |
|---|---|---|
| 1 | Root `pubspec.lock` in Renovate's commit | ✅ together with build_runner output and `dart format` changes, one commit by the App bot |
| 2 | Grouped branch, tasks once per branch | ✅ one `renovate/all` branch and commit; task ran once (`executionMode: branch`) |
| 3 | SDK rules | ✅ `^3.6.0` → `^3.13.0`, `>=3.27.0` → `>=3.47.0`; `custom.flutter-dart` override active |
| 4 | Global packageRules apply despite repo `renovate.json` | ✅ (proved with an artificial cap) |
| 5 | Presets via `github>Skycoder42/dart_test_tools//…` | ⏭ deferred to the end-to-end test (Task 12) |
| 6 | Notify sequence | ✅ DELETE (if pending) + POST `requested_reviewers` gives a mobile push on the 1st and a repeated CI run |
| 7 | Workspace-internal version-only deps | ❌→✅ Renovate looked `pure` up on pub.dev (an unrelated public package exists) → fixed with the workspace ignore rule (Component 1) |
| 8 | Library preset | ✅ weekly PR has only minor/patch (incl. 0.x patches, newest non-major e.g. `^2.4.4`); breaking updates wait in the dashboard; ticking the checkbox triggered the workflow via `issues: edited` and opened a separate `renovate/breaking` PR |

Further findings:
- **Indirect Flutter pins break PRs**: Renovate proposed `test ^1.33.0`, which needs
  `test_api 0.7.15` while `flutter_test` pins 0.7.12 → `pub upgrade` failed, PR red. Fixed by
  the resolvable caps (Component 1, decided by the user); verified green afterwards (`test`
  capped at 1.31.1, `build_runner` at 2.16.1).
- Flutter 3.47 pins only very few packages exactly (`material_color_utilities`, `test_api`,
  `matcher`); everything else uses `^` constraints.
- A failing task still lets Renovate commit what changed so far and open the PR with an
  "Artifact update problem" comment → the CLI should fail early (before writing files where
  possible).
- Data file: `depType` is an empty string (not missing) for SDK entries; one entry per package
  file, so the same dep/SDK appears once per member.
- The `issues: edited` guard (`!endsWith(github.actor, '[bot]')`) correctly skips Renovate's own
  dashboard edits.
- Cosmetic: the library breaking PR is titled "Update breaking updates (minor)" — choose a
  better `groupName` / commit message topic in the real preset.

## Phase 0b — `GITHUB_TOKEN` follow-up spike (done 2026-10-30)

Phase 0 ran with the GitHub App. After switching to `GITHUB_TOKEN` (2026-10-29), the same test
repo re-ran the spike workflow with `RENOVATE_TOKEN: ${{ github.token }}` and a hand-written
finish job (plan Task 4a), application preset, Renovate 44.190.2. The App was uninstalled and
its secrets deleted. The test repo's `.github/workflows/renovate-spike.yml` and `ci.yml` (job
`finish`) are now the reference for Tasks 6 and 8.

| # | Item | Result |
|---|---|---|
| T1 | Renovate opens the PR with `GITHUB_TOKEN`; commit and PR by `github-actions[bot]`; CI shows *Approve workflows to run* | ✅ PR #4 by `github-actions[bot]`; one commit, author `github-actions[bot]`, committer GitHub, **verified** (Renovate commits via the API); pubspecs, root `pubspec.lock`, build_runner output and formatting in that commit; CI run `action_required` |
| T2 | A second Renovate run recognises its own PR and branch (no duplicate PR, dashboard updated) | ✅ `branch.isModified() = false` (configured `gitAuthor` matches), "Pull Request #4 does not need updating", branch SHA unchanged, no second PR; dashboard ensured, not rewritten since unchanged |
| T3 | `RENOVATE_REVIEWERS` requests the owner at PR open → mobile push | ✅ push received |
| T4 | Approving the runs works from GitHub Mobile (or only on the web) | ✅ approved in the app |
| T5 | Red CI → comment with `@owner` mention → mobile push | ✅ comment "@Skycoder42 CI failed: <run URL>" by `github-actions`, push received, nothing merged |
| T6 | Green CI → `gh pr merge --match-head-commit … --delete-branch` merges and deletes the branch | ✅ squash-merged by `github-actions`, `renovate/all` deleted |
| T7 | A Renovate push after approval → new approval needed; merge with the old SHA refused | ✅ rebase (PR checkbox) pushed a new SHA whose run was `action_required` again; `gh pr merge --match-head-commit <old SHA>` → "Head branch was modified. Review and try the merge again." |
| T8 | `gh workflow run <ci> --ref main` from the finish job starts a run on main without approval | ✅ `workflow_dispatch` run on the merge commit, no approval; the merge itself started no `push` run (as expected) |
| T9 | Ticking a dashboard checkbox still triggers the caller via `issues: edited` | ✅ run started by the owner's tick; Renovate's own dashboard update afterwards started no run |

No fallback needed. Further findings:
- Renovate gets 403 "Resource not accessible by integration" for branch protection and branch
  rules (`administration` is not grantable to `GITHUB_TOKEN`). Logged at debug level only, no
  WARN/ERROR in any run; harmless.
- Renovate does not take over a Dependency Dashboard issue created by another identity: it
  opened a new one (the App's old issue stays orphaned). Only matters for repos that already ran
  Renovate under another identity — close the old issue by hand.
- Without automerge Renovate runs with `rebaseWhen=conflicted`: it does not rebase when the
  default branch moves, only on conflicts or when the PR's rebase checkbox is ticked (followed by
  a Renovate run — PR edits do not trigger the caller). The `pull_request` CI run tests the merge
  ref anyway. Each rebase needs a new workflow approval. Document the checkbox in the README
  ("fix landed on main → tick rebase, then run Renovate or wait for the schedule").
- The finish job itself ends green after posting the "CI failed" comment; the run is still red
  through the failed CI job. Fine as long as the caller's CI job stays required.
- With `cancel-in-progress` CI concurrency (common in consumers), a push during an approved run
  cancels that run; the finish job is then skipped via `!cancelled()`, so the SHA pin is only the
  second line of defence (follows from the workflow semantics; not run in the spike — T7 tested
  the pin directly).
- Not covered here (hand-written job in the caller): `GITHUB_WORKFLOW_REF` inside a *reusable*
  workflow naming the caller's file — verify in Task 12.

## Left to the builder

- Generator internals (job/step builder split, input naming within existing conventions).
- How the global config JSON is assembled in the workflow (script step, jq, …).
- Tests for the CLI (none exist today for auto-update) and whether to validate the presets with
  `renovate-config-validator` in this repo's CI.

## Background

Research notes (Dependabot limits, approval-required GITHUB_TOKEN runs since 2026-06, Renovate
pub/workspace behaviour, token exposure) were gathered in the brainstorming session on
2026-10-27; key facts are inlined above where they drive a decision.

`GITHUB_TOKEN` and workflow triggers (GitHub docs, checked 2026-10-29): a PR opened or updated
with `GITHUB_TOKEN` creates `pull_request` runs in an approval-required state (activity types
`opened`, `synchronize`, `reopened` only); a user with write access starts them via *Approve
workflows to run*. Apart from `workflow_dispatch` and `repository_dispatch`, other events caused
by `GITHUB_TOKEN` (e.g. the `push` of a merge) create no runs at all.
Sources: https://docs.github.com/en/actions/concepts/security/github_token,
https://docs.github.com/en/actions/reference/workflows-and-actions/events-that-trigger-workflows
