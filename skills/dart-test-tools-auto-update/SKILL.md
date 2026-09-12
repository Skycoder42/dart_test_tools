---
name: dart-test-tools-auto-update
description: >-
  Use when the user wants to run or repair the automatic dependency update of a dart or
  flutter package — either starting a fresh update from the default branch, or working on
  the update that is already open on the 'automatic-dependency-updates' branch. Resolves
  which of the two it is, puts the worktree on the right branch, and for a fresh update
  reproduces the shared auto-update CI workflow locally.
license: BSD-3-Clause
user-invocable: true
argument-hint: "[new|existing] [force]"
allowed-tools:
  - Bash(bash ${CLAUDE_SKILL_DIR}/scripts/prepare-update.sh:*)
---

# Automatic dependency updates

`dart_test_tools` ships a reusable workflow,
`Skycoder42/dart_test_tools/.github/workflows/auto-update.yml`, that updates a package's
dependencies and opens a pull request from the `automatic-dependency-updates` branch.
This skill drives the same thing locally. There are exactly two situations:

| Situation | Branch | Mode |
| --- | --- | --- |
| Start a **new** dependency update | the default branch (`main`) | `new` |
| Work on the update that is **already open** | `automatic-dependency-updates` | `existing` |

## Scope

This skill currently covers **only the first step**: working out which of the two
situations applies, getting the worktree onto the matching branch, and — for a new
update — running the update itself. When the script has finished, report what it
returned and stop.

Do not fix anything, do not analyse failures, do not commit and do not push. That comes
afterwards, separately.

## Step 1 — run the resolver

```sh
bash ${CLAUDE_SKILL_DIR}/scripts/prepare-update.sh [<mode>] [ignore-branch]
```

Translate the skill's argument into the script's arguments:

| Skill invoked as | Run |
| --- | --- |
| *(no argument)* | `prepare-update.sh` |
| `new` | `prepare-update.sh new` |
| `existing` | `prepare-update.sh existing` |
| `new force` | `prepare-update.sh new ignore-branch` |
| `existing force` | `prepare-update.sh existing ignore-branch` |

- With **no mode**, the script derives the mode from the branch that is checked out and
  fails if it is neither of the two. Prefer this when the user did not say which it is.
- With **a mode**, the script switches to the matching branch — but only if the worktree
  is clean. On a dirty worktree it refuses and tells you so.
- `ignore-branch` is the escape hatch the user asks for with "force": it skips every git
  check and takes the given mode at face value. Only pass it when the user explicitly
  asked to force it, and never on its own — it always needs a mode.

Run the script exactly once. It is the only command this skill needs; do not reach for
`git`, `yq` or `auto_update` yourself.

## Step 2 — read the record

The script prints a machine readable record on stdout. Everything else it writes goes to
stderr and is progress noise.

```
>>> auto-update-prepare
status: ok
mode: new
...
<<< auto-update-prepare
```

Rules: one `key: value` per line, keys lowercase, values single-line, and everything
after the first `: ` belongs to the value. `warning` may appear any number of times (or
not at all), every other key at most once.

Always present:

| Key | Meaning |
| --- | --- |
| `status` | `ok`, or `error` when the script itself failed |
| `mode` | `new` or `existing` — the situation that was resolved |
| `branch` | the branch the worktree is on now |
| `branch_check` | `derived` (read off the branch), `matched` (already correct), `switched` (checked out for you) or `ignored` (`ignore-branch` was passed) |
| `repo_root` | absolute path of the repository |

Only when `mode: new`, describing the update run:

| Key | Meaning |
| --- | --- |
| `workflow_file` | the workflow that calls the shared auto-update workflow, or `none` |
| `workflow_job` | the job inside it, or `none` |
| `target` | the package directory the update ran against |
| `update_command` | the exact `auto_update` invocation, arguments included |
| `update_exit_code` | its exit code — **`0` does not always mean there is nothing to report** |
| `update_log` | absolute path to its combined stdout/stderr |
| `update_report` | absolute path to the markdown report, or `none` |

Only when `status: error`:

| Key | Meaning |
| --- | --- |
| `error` | why the script could not continue |

A non-zero `update_exit_code` is **not** a script failure — the script still exits `0`
and reports it. It only exits non-zero when it could not do its own job at all
(dirty worktree blocking a switch, neither branch checked out, a missing tool).

## Step 3 — report, then stop

Read `update_report` if it exists, otherwise `update_log`, and summarise for the user:

- **`mode: existing`** — say which branch you are on and that the existing update is ready
  to be worked on. Nothing was run.
- **`mode: new`, `update_exit_code: 0`** — summarise what the report says was updated, and
  point at `update_report` / `update_log`.
- **`mode: new`, non-zero `update_exit_code`** — say the update ran but failed, quote the
  relevant lines from `update_log`, and point at the file. Do not start fixing it.
- **`status: error`** — relay the `error` value and what the user has to do about it
  (commit or stash their changes, check out one of the two branches, install the missing
  tool). Do not work around it on your own.

Always surface every `warning` line. They are the ones that change what the run actually
did — a missing caller workflow means the update ran with defaults instead of the
package's real settings, and a stale branch means you may be looking at the wrong code.

Then stop and wait.

## Notes

- For a new update the script mirrors the workflow's `Update dependencies` step, so it
  passes `--mode update --bump-version --report` alongside the `workingDirectory` and
  `flutterCompat` inputs it read from the caller workflow. That means the run bumps the
  version and writes a `CHANGELOG.md` entry, exactly like CI would.
- If no workflow calls the shared auto-update workflow, that is a warning, not an error:
  the script falls back to the repository root and `auto_update`'s own defaults.
- The script needs `git`, `dart` and `yq` on `PATH`.
