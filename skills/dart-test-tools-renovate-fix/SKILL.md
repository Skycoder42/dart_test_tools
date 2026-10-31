---
name: dart-test-tools-renovate-fix
description: >-
  Use when a Renovate dependency-update PR of a dart or flutter package is red, or the
  user wants to reproduce or repair it locally. Checks out the PR branch, re-runs the
  renovate-post-upgrade step Renovate runs inside its commit, validates the package the
  way CI would and helps fix what fails. When Flutter moved to a new minor version, it
  offers to update the native platform projects as well.
license: BSD-3-Clause
user-invocable: true
argument-hint: "[<pull request>] [skip-post-upgrade | allow-dirty]"
allowed-tools:
  - Bash(bash ${CLAUDE_SKILL_DIR}/scripts/prepare-fix.sh:*)
  - Bash(gh pr checks:*)
  - Bash(gh run view:*)
  - Bash(git diff:*)
  - Bash(dart analyze:*)
  - Bash(flutter analyze:*)
  - Bash(dart format -onone --set-exit-if-changed:*)
  - Bash(dart test:*)
  - Bash(flutter test:*)
  - Bash(dart pub publish --dry-run)
  - mcp__dart__analyze_files
---

# Repairing a Renovate pull request

`dart_test_tools` updates dependencies with self-hosted Renovate: the reusable
`Skycoder42/dart_test_tools/.github/workflows/renovate.yml` workflow opens a pull request
from a `renovate/…` branch (`renovate/all` for the weekly update, `renovate/breaking` for
approved breaking updates of the library preset). The pull request has exactly one commit
by `github-actions[bot]`. It contains Renovate's constraint changes plus everything the
`renovate-post-upgrade` CLI did in the same commit: dependency resolution, analyzer plugin
pins, build_runner, `dart format`, `dart fix`, changelog entries and a patch release.
Once the owner approved the CI runs, a finish job at the end of CI merges the pull
request when CI is green, or comments with a mention when it is red.

Such a pull request turns red in one of two ways:

- **The post-upgrade step failed inside Renovate.** Renovate then commits what changed
  so far and comments "Artifact update problem" on the pull request. The commit is
  incomplete.
- **The post-upgrade step succeeded, but CI fails** — typically a breaking change in an
  updated dependency, a new lint, or a test that now behaves differently.

The skill runs in phases. **Phase 1** finds the pull request, checks out its branch and
re-runs the post-upgrade step locally. **Phase 2** validates the package against the
checks CI performs and fixes what fails. **Phase 3** tells the user how to finish.
**Phase 4** only applies after a new Flutter minor (or major) version: it offers to
update the native platform projects too.

Throughout: **never commit, never push, never publish for real.** Working-tree changes
plus a summary are the whole output.

---

## Phase 1 — check out the branch and re-run the post-upgrade step

```sh
bash ${CLAUDE_SKILL_DIR}/scripts/prepare-fix.sh [<pull request>] [skip-post-upgrade | allow-dirty]
```

Pass the skill's arguments through unchanged.

- **`<pull request>`** is a number, URL or branch. Without it, the script takes the pull
  request of the checked out `renovate/…` branch, or else the only open Renovate pull
  request. With several open and none checked out, it stops and lists them — ask the user
  which one, then run it again with that one.
- The script only switches branches on a clean worktree. On a dirty one it refuses.
- **`skip-post-upgrade`** — only describe the packages, do not re-run the post-upgrade
  step. Use it when the user only wants the state of the branch validated.
- **`allow-dirty`** — re-run the post-upgrade step although the worktree has changes.
  Use it only for the re-run after fixing the cause of a failed run (see below), or when
  the user explicitly asks for it.

Run the script exactly once per attempt. Do not reach for `git`, `gh`, `yq` or the
post-upgrade CLI yourself to do what it does.

### What the re-run does

Renovate always builds its commit from the base branch, so the post-upgrade step never
sees its own output. The script rebuilds Renovate's data file from the constraint changes
of the pull request's `pubspec.yaml` files. It then undoes the only two things a second
run would duplicate: the changed `CHANGELOG.md` files are restored to the base branch,
and the `version:` of the changed pubspecs is set back to its base value. Then it runs
`renovate-post-upgrade --mode <preset>` from the repository root, like Renovate does.
Everything else the step does converges when it runs again.

It uses the globally activated `renovate-post-upgrade` if there is one (that is what CI
runs). Otherwise it uses the `dart_test_tools` that a package of the repository depends
on.

### The record

The script prints a machine readable record on stdout; everything else it writes goes to
stderr and is progress noise.

```
>>> renovate-fix
status: ok
pr_number: 12
...
<<< renovate-fix
```

One `key: value` per line. Keys are lowercase and may be dotted and indexed
(`package.1.name`); values are single-line; everything after the first `: ` belongs to
the value. `warning` may appear any number of times, every other key at most once.

Always present:

| Key | Meaning |
| --- | --- |
| `status` | `ok`, or `error` when the script itself failed |
| `pr_number` / `pr_title` / `pr_url` | the Renovate pull request |
| `checks_failed` | names of the failed checks of the **pushed** head commit, `none`, or `unknown` |
| `checks_pending` | how many checks have not finished yet (or `unknown`) — runs still waiting for approval show up here |
| `artifact_error` | `yes` when Renovate reported an "Artifact update problem" — the post-upgrade step failed in Renovate |
| `branch` / `branch_check` | the branch the worktree is on now; `matched` (already checked out) or `switched` |
| `base_branch` / `base_commit` | the branch the pull request targets, and where the Renovate branch forked off it |
| `renovate_commits` / `other_commits` | commits on the branch by Renovate, and by anyone else |
| `repo_root` | absolute path of the repository |
| `preset` / `preset_file` | `library`, `application` or `unknown`, read from the Renovate config file |
| `post_upgrade` | what happened to the post-upgrade step, see below |
| `post_upgrade_data` / `post_upgrade_entries` | the rebuilt data file and its number of pub upgrades |
| `flutter_min_base` / `flutter_min_now` | the highest minimum Flutter version any package declares, at `base_commit` and now, or `none` |
| `flutter_update` | how far that moved: `major`, `minor`, `patch`, `none`, or `n/a` when it cannot be compared |
| `flutter_apps` | how many flutter app projects (with native platform folders) the repository has |
| `root_count` / `root.<n>.path` | the pub roots the update touched (a package, or a workspace root) — **run analyze and format from here** |
| `package_count` | how many `package.<n>.*` groups follow |

`post_upgrade` is one of:

| Value | Meaning |
| --- | --- |
| `ran` | the step ran; see the keys below |
| `skipped-request` | `skip-post-upgrade` was passed |
| `skipped-no-pub` | the pull request changed no pub constraint (an update of another manager only, e.g. npm) — the CLI would not do anything either |
| `skipped-no-preset` | the Renovate config extends neither preset of dart_test_tools, so the mode is unknown |
| `skipped-dirty` | the worktree had changes and `allow-dirty` was not passed |
| `unavailable` | the CLI was found neither on `PATH` nor in a resolved `dart_test_tools` |

Only when `post_upgrade: ran`:

| Key | Meaning |
| --- | --- |
| `post_upgrade_command` | the exact invocation |
| `post_upgrade_exit_code` | its exit code |
| `post_upgrade_log` | absolute path to its combined stdout/stderr |
| `post_upgrade_reset` | how many files were reset before the run (changelogs and pubspec versions) |
| `changed_files` | how many files now differ from the branch head |

One group per package, `<n>` from 1 to `package_count`:

| Key | Meaning |
| --- | --- |
| `package.<n>.name` | package name from its pubspec |
| `package.<n>.path` | absolute directory — **run publish and tests from here** |
| `package.<n>.root` | the index of its `root.<n>` |
| `package.<n>.tool` | `dart` or `flutter`; use it for `analyze` and `test` |
| `package.<n>.publishable` | `yes` unless the pubspec says `publish_to: none` |
| `package.<n>.build_runner` | `yes` when codegen has to run before anything else compiles |
| `package.<n>.unit_tests` | paths to pass to `test`, or `none` |
| `package.<n>.integration_tests` | paths CI runs separately — **never run these** |
| `package.<n>.test_source` | `workflow` (read off the CI caller — authoritative) or `heuristic` (guessed from the directory layout) |

Only when `status: error`, an `error` key says why the script could not continue.

A non-zero `post_upgrade_exit_code` is **not** a script failure — the script still exits
`0` and reports it.

### Before moving on

- **`status: error`** — relay the `error` value and what the user has to do about it
  (commit or stash their changes, pick one of several pull requests, authenticate `gh`,
  install a missing tool). Stop here; do not work around it on your own.
- **`post_upgrade_exit_code` non-zero** — read `post_upgrade_log` and say which step
  failed. This is the first problem to solve in phase 2. The worktree is now as far as
  the step got, just like Renovate's incomplete commit. Once the cause is fixed, run the
  script again with `allow-dirty`. It resets the changelogs and versions again, so the
  re-run does not add a second entry or bump.
- **`post_upgrade: ran` with exit code `0`** — `git diff` shows where the local run
  differs from what is pushed.
  - With `artifact_error: yes` that difference is the part Renovate failed to commit —
    keep it.
  - Otherwise expect little or nothing. If a `CHANGELOG.md` differs only in the release
    date, restore that file — the pushed one is correct. In the application preset,
    newer transitive versions in `pubspec.lock` are fine either way. Anything else is
    worth a sentence to the user.
- **`other_commits` greater than `0`** — someone already pushed to the branch, so Renovate
  treats it as edited and stops updating it. The changelog reset may have dropped
  changelog lines from those commits; check the diff of every `CHANGELOG.md`.
- **`root_count: 0`** — the pull request changed no pubspec. There is nothing pub-related
  to validate. Look at `checks_failed` and the CI logs instead, and tell the user what
  you found.
- **Always surface every `warning`.** A branch that is behind its origin means Renovate
  rebuilt it and you are looking at an outdated update — ask the user whether to update
  the local branch. Do not reset it yourself.

---

## Phase 2 — validate the package state

Start with what CI already said. If `checks_failed` is not `none`, read the failing log
first — `gh pr checks <pr_number>` lists the runs, and `gh run view <run id> --log-failed`
shows the failure. It tells you which of the checks below to look at first. It describes
the pushed commit, not the local worktree.

Then reproduce the checks the CI runs, in this order, and **keep going until they all
pass**. Where each one runs depends on the record:

| # | Check | Where | Command |
| --- | --- | --- | --- |
| 1 | Static analysis | once per root, at `root.<n>.path` | `mcp__dart__analyze_files` if that tool is available, else `dart analyze --fatal-infos` (`flutter analyze` for a flutter package) |
| 2 | Formatting | once per root, at `root.<n>.path` | `dart format -onone --set-exit-if-changed $(git ls-files '*.dart')` |
| 3 | Publishing | per package with `publishable: yes`, at its `path` | `dart pub publish --dry-run` |
| 4 | Unit tests | per package with `unit_tests` other than `none`, at its `path` | `<tool> test <unit_tests>` |

Notes that matter:

- **`--dry-run` is not optional.** Never run `dart pub publish` without it, under any
  circumstance, for any reason. This skill never publishes.
- **Never run the `integration_tests` paths.** They routinely need setup — emulators,
  credentials, an installed Flutter SDK — that is out of scope here. A package whose
  `unit_tests` is `none` simply has no tests to run in this phase; that is a normal,
  passing outcome, not something to work around by running the integration paths instead.
- **`test_source: heuristic`** means no CI caller workflow covered that package, so the
  unit/integration split was guessed from the layout. Glance at what is actually in those
  paths before running them, and say so if they look like integration tests.
- **`build_runner: yes`** means generated sources (`*.g.dart`, `*.freezed.dart`) are
  required. If analysis fails with missing parts or unresolved generated identifiers, run
  `dart run build_runner build --delete-conflicting-outputs` at the package and retry —
  that is a missing build step, not a code defect.
- `--fatal-infos` matches CI. Plain `dart analyze` lets info-level lints through and would
  "pass" locally against a red CI.
- If you use the MCP analyzer, it reports the same diagnostics but does not apply the
  `--fatal-infos` threshold for you — treat info-level findings as failures too.

### The loop

1. Run the next check.
2. If it passes, move to the next one.
3. If it fails, **stop and diagnose before running anything else.** Read the actual error.
   Work out whether it is a consequence of the dependency update (a breaking change, a
   new lint, a changed API) or something unrelated that was already broken.
4. Resolve it — fix it yourself or ask the user, per the rules below.
5. After any change, **restart from check 1.** Fixes interact: applying analyzer fixes
   reformats code, regenerating sources changes what analysis sees, and a dependency bump
   can turn a passing test red.

Stop looping when all four pass, or when you are blocked on a decision that is the user's
to make. Do not loop on the same failure twice without changing something.

### Fix it yourself, or ask?

Decide honestly. The cost of a wrong autonomous "fix" here is a dependency update that
silently changes behaviour, so bias towards asking whenever the *intent* is unclear.

**Fix without asking** — mechanical, intent-preserving, verifiable:

- Formatting (`dart format` over the offending files).
- Missing or stale generated sources (`dart run build_runner build --delete-conflicting-outputs`).
- Lints with a single obvious mechanical fix, including what `dart fix --apply` resolves.
  Re-analyze afterwards; `dart fix` occasionally rewrites more than expected.
- Imports that moved within an updated dependency, where the replacement is unambiguous.

**Ask the user** — anything where more than one answer is defensible:

- A dependency's breaking change where the choice is *adapt the code* vs *hold the
  dependency back*. Say what each would cost. Holding back means a `packageRules` entry in
  the Renovate config (for example `allowedVersions`) on the default branch, followed by a
  rebuild of the pull request — see phase 3.
- A deprecation with several valid migrations, or one that changes public API.
- A failing test where it is not obvious whether the test or the code is now wrong.
- `dart pub publish --dry-run` complaining about package metadata — description, homepage,
  license, oversized files. These are author decisions.
- Anything that would change behaviour the tests do not pin down.

**Never do these**, even if they would make a check pass:

- Delete, skip or weaken a test.
- Relax `analysis_options.yaml`, or add ignore comments to silence a real finding.
- Pin a dependency backwards to dodge a failure without saying so explicitly. Do not edit
  the constraints Renovate wrote in the pubspecs at all — Renovate would bring them back.
- Edit the changelog entries or the version the post-upgrade step wrote.
- Edit `.github/workflows/*.yml` directly — in these repositories they are generated from
  `tool/ci_gen/` and regenerated with `dart run tool/ci_gen.dart`.
- Commit, push, tick checkboxes on the pull request or the dependency dashboard, or drop
  `--dry-run`.

### Reporting

When the loop ends, tell the user:

- Which checks pass now, and which package each result belongs to when there are several.
- Every change you made and why, grouped by cause — separate what the post-upgrade re-run
  produced, what the dependency update forced, and what was already broken.
- Anything you deliberately left alone, and the decision you need from them.

Then continue to phase 3.

---

## Phase 3 — tell the user how to finish

The user commits and pushes. Explain the two ways to get the fix in, and what happens
after each. Pick the one that fits and say why.

1. **Push the fix onto the Renovate branch.** Fits when the fix only makes sense together
   with the update (adapting to a breaking change, the part of the post-upgrade step that
   Renovate failed to commit).
   - A push by the user starts CI without an approval.
   - When CI is green, the finish job merges the pull request. It checks who opened the
     pull request, not who pushed, so the fix is merged together with the update.
   - From then on Renovate treats the branch as edited and stops updating it. Ticking the
     rebase checkbox in the pull request makes Renovate rebuild the branch from scratch,
     which **throws the fix away**. Only tick it once the fix is on the default branch.
2. **Land the fix on the default branch first.** Fits when the fix stands on its own
   (something that was already broken), or when a dependency is held back through the
   Renovate config.
   - Renovate does not rebase when the default branch moves. Afterwards, tick the pull
     request's rebase checkbox and run the Renovate workflow by hand, or wait for its
     schedule.
   - The rebuilt commit needs a new *Approve workflows to run*.

Then go to phase 4. If it does not apply, stop there.

---

## Phase 4 — offer a native project update

The dependency update never touches the native platform projects of a flutter app
(`android/`, `ios/`, `linux/`, `macos/`, `web/`, `windows/`). Their templates move with
Flutter releases. If they are left behind, a native build eventually breaks — for example
when a plugin needs a newer Gradle, Android Gradle Plugin or deployment target.

Only offer the native update when **both** of these hold. Otherwise do not mention it.

- `flutter_update` is `major` or `minor`.
- `flutter_apps` is greater than `0`.

Ask only after the phase 2 report, never before. Name the versions
(`flutter_min_base` → `flutter_min_now`) and ask whether the native projects should be
updated as well.

- **No** — stop. The user commits.
- **Yes** — hand over to the `dart-test-tools-native-update` skill. It only runs on a
  clean working tree, and the fix has just left changes behind. So:
  1. Ask the user to commit the fix first. This skill still never commits itself, and
     the two changes belong in separate commits anyway.
  2. Once they confirm, invoke the `dart-test-tools-native-update` skill and follow it.
     Its changes go the same way as the fix (phase 3, option 1).
