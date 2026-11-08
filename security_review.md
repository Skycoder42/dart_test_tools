# Security review: Renovate flow

Date: 2026-11-07 · Scope: `renovate.yml`, `renovate-finish.yml`, the presets in
`renovate/`, the `renovate-config` and `renovate-post-upgrade` CLIs, the callers in
this repo and the repository settings of `Skycoder42/dart_test_tools`.
Focus: what someone **without write access** can do, in particular by forking the
repository and opening a pull request.

Legend: ✅ backed by official docs, the installed Renovate source (44.205.2 in
`tool/renovate/node_modules/renovate`) or a read-only API call · ⚠️ inferred, not
documented · ❓ unverified

## Summary

A fork PR on its own cannot reach a merge or a write token: there is no path from a
fork PR to `renovate-finish` or to Renovate's own PR handling. The weaknesses sit next
to the flow:

1. Any GitHub account can start the Renovate job (write token) via the `issues: edited`
   trigger.
2. `main` of this repo is unprotected while every consumer uses `@main`, so code that
   runs inside the Renovate job can push to `main` and spread to all consumers.
3. Default-branch content executes inside the Renovate job, so contributor PRs that
   touch `pubspec.yaml` (`renovate:` section), `build.yaml`, analyzer plugins or
   `tool/renovate/package-lock.json` are the real fork-PR risk and are easy to miss in
   review.

## Repository settings (read via API on 2026-11-07)

| Setting | Value |
|---|---|
| Visibility | public |
| Rulesets / classic protection on `main` | none ("Branch not protected") — ruleset added afterwards, see finding 2 |
| Allow auto-merge | off |
| Fork PR approval policy | `first_time_contributors` |
| Default workflow permissions | read |
| Actions may create/approve PRs (`can_approve_pull_request_reviews`) | true |
| Allowed actions | all, SHA pinning not required |

## Fork PRs: vectors checked and found not exploitable

| Vector | Why it fails | Basis |
|---|---|---|
| Fork PR edits the CI caller, e.g. passes a fake `needs` to `renovate-finish` | Fork PRs get a read-only `GITHUB_TOKEN` and no secrets, so `gh pr merge` cannot succeed. The finish job additionally requires `head.repo.full_name == github.repository`. | ✅ GitHub events docs; `.github/workflows/renovate-finish.yml` |
| Fork PR from a branch named `renovate/all` | Finish job requires author `github-actions[bot]` **and** same repo. Renovate filters PRs by its own login (`getPrCache`) and requires `sourceRepo == repository` (`findPr`). | ✅ `platform/github/{index,pr}.js` |
| Attacker lets a bot (their fork's `github-actions[bot]` run, or their own GitHub App) open the PR so the author check passes | See the dedicated section below: the fork's token cannot act on the upstream repo; a foreign App has a different login; and the head-repo check and the read-only token are independent of the author anyway. | ✅ / ⚠️ |
| Fork PR changes `renovate.json`, presets or `pubspec.yaml` | Renovate and `renovate-config` read the default branch only; `issues` runs use the default branch too. Nothing takes effect before a merge. | ✅ |
| Fork PR poisons a cache that the Renovate run or a CI run on `main` restores later | PR caches are scoped to `refs/pull/N/merge` and cannot be written to the default branch's scope. The `issues` trigger has read-only cache access. | ✅ caching docs |
| Injection via the post-upgrade data file (`depName`, `newValue`, `packageFile`) | The command is fixed (`allowedCommands`), the data file is parsed as JSON and never reaches a shell. Pub versions cannot contain `"`. | ✅ code / ⚠️ pub version grammar |
| Fake "Dependency Dashboard" issue used to approve held majors | Renovate only reads issues with `createdBy` = its own login (`getIssuesQuery`). | ✅ |

### Why a bot-authored PR from a fork does not pass the checks

Question: could an attacker have a GitHub bot create the branch and PR from their fork,
so that the `github-actions[bot]` author check passes?

1. **The fork's own `GITHUB_TOKEN` cannot open a PR in this repo.** ✅ GitHub: "The
   token's permissions are limited to the repository that contains your workflow." A
   PR is created with `POST /repos/Skycoder42/dart_test_tools/pulls`, i.e. a write on
   *this* repo, which the fork's token does not have. A PR authored by
   `github-actions[bot]` in this repo can therefore only come from a workflow run of
   this repo.
2. **An attacker's own GitHub App has a different login.** Its PRs are authored as
   `<app-name>[bot]`, never `github-actions[bot]` (that login belongs to the shared
   GitHub Actions app, user id 41898282). ⚠️ To create a PR in this repo at all, the
   App would have to be installed on this repo, which only the owner can do.
3. **The author check is not the only gate.** Even with a forged author, the finish job
   requires `head.repo.full_name == github.repository` (the branch must live in this
   repo, which needs write access), and Renovate requires `sourceRepo == repository`.
   On top of that, a `pull_request` run from a fork gets a read-only token, so the
   merge step cannot succeed regardless of the conditions.

So the author check is defense in depth; the head-repo check plus the read-only
fork token are the actual barrier.

## Findings

### 1. Anyone can trigger the Renovate job — Medium · **fixed 2026-11-07**

Where: `.github/workflows/dart_test_tools_renovate.yml` (`issues: edited`) and the job
condition in `renovate.yml`:
`github.event.issue.title == 'Dependency Dashboard' && !endsWith(github.actor, '[bot]')`.

- **How:** any GitHub account opens an issue titled "Dependency Dashboard" and edits
  it (title or body). The guard only checks the title and that the actor is no bot.
  - ✅ Anyone with read access can open issues and edit their own.
  - ✅ The `issues` event needs no approval (approval exists for fork PRs only) and
    runs the default-branch workflow with `contents`, `pull-requests`, `issues` and
    `statuses: write`.
- **Effect:** the attacker controls *when* Renovate runs, not what it does. That
  matters because each run executes code from *new* dependency versions before anyone
  sees a diff: `pub get`/`pub upgrade`, `build_runner`, analyzer plugins via
  `dart fix`. The owner's "Approve workflows to run" only gates CI, not this step.
- **Timing:** someone who publishes or hijacks a dependency version can have it
  executed within minutes instead of waiting for the weekly cron. (The library preset
  has no `minimumReleaseAge`, but adding one would not help: see the correction under
  finding 2.)
- **Lesser effect:** repeated edits cause back-to-back runs that use up the
  repository's API quota (⚠️; the concurrency group keeps at most one pending run).
  Cache poisoning is not possible from this trigger (read-only cache access, ✅).
- **Fix:** add `github.event.issue.user.login == 'github-actions[bot]'` to the job
  condition, so only Renovate's own dashboard issue can trigger it. Editing that
  issue's body/title is possible only for users with write access or the author.
- **Done:** condition added in `tool/ci_gen/renovate/jobs/renovate_job_builder.dart`,
  `.github/workflows/renovate.yml` regenerated. It now reads
  `github.event_name != 'issues' || (github.event.issue.title == 'Dependency Dashboard'
  && github.event.issue.user.login == 'github-actions[bot]' && !endsWith(github.actor,
  '[bot]'))`. Consumers get it on their next run, since they call `renovate.yml@main`.
  Not tested end-to-end (that needs an issue edit in a real repository).

### 2. `main` is unprotected while every consumer uses `@main` — High impact, needs a foothold · **mitigated 2026-11-07**

- ✅ Verified by API: no rulesets, no classic protection.
- **How:** Renovate's token is reachable from every post-upgrade step (documented in
  the design). Malicious dependency code (finding 1) or any other leak can push
  straight to `main` of this repo.
- **Spread:** consumers reference `install-tools@main`, the reusable workflows
  `@main` and the presets `github>Skycoder42/dart_test_tools//renovate/*` without a
  tag. One push reaches every consumer's Renovate job (write tokens) on its next run.
  - ✅ `GITHUB_TOKEN` has no `workflows` permission, so `.github/workflows/*` cannot
    be changed.
  - ❓ Whether `.github/actions/*` and `renovate/*.json` are protected the same way is
    not established. A preset that sets `registryUrls` or `hostRules` would already be
    enough to redirect consumers to a malicious package host.
- **Fix:** add the ruleset the design document already recommended (`main` only via
  PR plus status checks, owner on the bypass list).
- **Correction (2026-11-07):** this finding originally also recommended restoring a
  minimum release age for libraries. That was wrong. Libraries have no lockfile, so
  `pub get` in the post-upgrade step (and in CI) resolves transitive dependencies to
  their newest versions anyway; an age gate on direct dependencies would not keep a
  malicious new transitive version out. This is the reason commit 618d16d moved the
  rule to applications only. Dropped.
- **Done:** ruleset "Protect default branch" (id 26752138) created via
  `POST /repos/Skycoder42/dart_test_tools/rulesets`, enforcement active, target
  `~DEFAULT_BRANCH`:
  - `deletion` and `non_fast_forward` (no deleting, no force push);
  - `pull_request` with 0 required approvals (a required review would block the
    `renovate-finish` merge, see the design document);
  - `required_status_checks`, not strict, each bound to the GitHub Actions app
    (integration id 15368): `CI / Analyze`, `CI / Flutter compatibility`,
    `CI / Integration tests (linux|macos|web|windows)`. These are the checks that ran
    on both `main` and Renovate PR #109; `Unit tests` and `Validate coverage` are
    skipped in this repo and were left out;
  - bypass: repository role Admin, mode `always`. Verified via API:
    `current_user_can_bypass: always`, so direct pushes by the owner keep working.
- **Effect:** a leaked or abused `GITHUB_TOKEN` can no longer push to `main`, force
  push or delete it. To change `main` it has to go through a PR whose required checks
  passed.
- **Residual risk (❓ unverified):** the Renovate job needs `statuses: write` (Renovate
  sets `renovate/stability-days` on its commits). A commit status created with
  `GITHUB_TOKEN` is probably attributed to the same GitHub Actions app (15368) as the
  real CI checks, so a malicious post-upgrade step could create a branch and PR, post
  forged `success` statuses with the required names and merge. If that holds, the
  ruleset only raises the bar for that path. Verify in `Skycoder42/renovate-test`
  before relying on it. Possible remedies: disable Renovate's status checks and drop
  `statuses: write`, or bind the required checks in a way commit statuses cannot
  satisfy (needs research).
- **Maintenance:** the required check names must follow CI. Renaming a job or
  changing the integration test platforms leaves a required check that is never
  reported, which blocks every PR (the owner can still bypass). PRs that only touch
  the paths in CI's `paths-ignore` (`flatpak/flutter-extension`, its workflow) get no
  CI run and stay blocked for the same reason; merge those with the bypass.

### 3. Contributor PRs that change the execution surface are easy to miss — Medium (the actual fork-PR risk)

Once merged, default-branch content runs inside the Renovate job with the write
token:

- `renovate.pre_build_command` in `pubspec.yaml` (commit 2a1e81d) runs through
  `/bin/sh -c` (`PubWrapper.runShellCommand`).
- Local builders in `build.yaml` (run by `build_runner`).
- Analyzer plugins (loaded by `dart fix`).

The design's statement that `allowedCommands` only permits `renovate-post-upgrade` is
therefore not a boundary for repository content (strictly, it never was, because
`build_runner` already runs repo code).

Special case, affecting every consumer: a PR that touches
`tool/renovate/package-lock.json` can point a `resolved` URL at an attacker-controlled
tarball with a matching `integrity` hash (lockfile injection); nobody reviews
5,000-line lockfile diffs. ⚠️ That `npm ci` follows non-registry `resolved` URLs is
known npm behavior, not re-checked against the npm docs here. The `.npmrc` mentioned
in the design does not exist in `tool/renovate/`.

- **Fix:** run `lockfile-lint` (allowed host `registry.npmjs.org`, https only) in CI;
  add a `CODEOWNERS` entry or a review checklist for `pubspec.yaml` `renovate:`
  sections, `build.yaml`, `analysis_options.yaml`, `tool/renovate/**`, `renovate/**`
  and `lib/src/renovate/**`.

### 4. Repository settings that weaken the setup — Low

- **Fork PR approval** is `first_time_contributors`: after one merged PR, a
  contributor's fork PRs run without approval. They still get read-only tokens, but
  can use the runners and read default-branch caches, including Renovate's repository
  cache (public data in a public repo). Consider "all external contributors".
- **Actions may approve PRs** (`can_approve_pull_request_reviews: true`; the setting
  Renovate needs to open PRs). Any `GITHUB_TOKEN`, including one taken by a malicious
  dependency, can approve PRs. Irrelevant today (no required reviews), but it would
  defeat a "required approvals" rule later.
- **Actions policy** allows all actions and does not require SHA pinning. The
  generated workflows pin SHAs; enforcing it would catch hand-written ones.

### Not security, but a bug

The README documents per-platform maps for `pre_build_command`, but
`PubWrapper.renovatePreBuildCommand()` only accepts a string and throws on a map.

## Recommended order

1. ~~Restrict the dashboard trigger to the bot's own issue~~ (done, finding 1).
2. ~~Ruleset on `main` with the owner on the bypass list~~ (done, finding 2; residual
   risk via forged commit statuses still to verify).
3. ~~Minimum release age back for the library preset~~ (dropped, see the correction
   under finding 2).
4. `lockfile-lint` plus `CODEOWNERS` on the execution-surface files.
5. Fork approval for all outside contributors.

## Work log

Every change made as a result of this review is recorded here.

- 2026-11-07: review performed, findings written to this file. No code or settings
  changed yet.
- 2026-11-07: finding 1 fixed. Issue-author condition added to the Renovate job in
  `tool/ci_gen/renovate/jobs/renovate_job_builder.dart`; workflows regenerated with
  `dart run tool/ci_gen.dart`; analysis clean. The regeneration also updated
  `.github/actions/install-tools/action.yml` from `dart_test_tools ^8.1.2` to `^8.1.3`.
  That is drift unrelated to this review: Renovate PR #109 bumped the version to
  8.1.3, but the post-upgrade step does not run `tool/ci_gen.dart`, so the generated
  file was left behind. Changelog entry added under `[Unreleased]` / Security via
  `dart run bin/cider.dart log security …` (no version bump).
- 2026-11-07: finding 2 mitigated. Ruleset "Protect default branch" (id 26752138)
  created on `Skycoder42/dart_test_tools` via the GitHub API (details under finding
  2) and verified with `GET /rules/branches/main`. The recommendation to restore a
  minimum release age for libraries was withdrawn (correction under finding 2).
- 2026-11-07: finding 3, lockfile part done. Step "Lint Renovate lockfile" added to
  the `renovate-lockfile` job in `.github/workflows/dart_test_tools_ci.yml`
  (hand-written, not generated). `lockfile-lint` (`^5.1.0`) is a devDependency in
  `tool/renovate/package.json`, configured under its `lockfile-lint` key
  (`allowedHosts: npm`, https, integrity and package-name validation; the three
  `npm:` aliases from `@isaacs/cliui` — `string-width-cjs`, `strip-ansi-cjs`,
  `wrap-ansi-cjs` — allowed explicitly) and run as `npm run lint-lockfile` after
  `npm ci --ignore-scripts`. The reusable `renovate.yml` now installs with
  `--omit=dev` (`tool/ci_gen/renovate/steps/renovate_builder.dart`, regenerated).
  Checked locally: the current lockfile passes, and a copy with one `resolved` URL
  pointed at another host fails. `CODEOWNERS` / review checklist still open.

## Sources

- GitHub docs
  - [Events that trigger workflows](https://docs.github.com/en/actions/reference/workflows-and-actions/events-that-trigger-workflows)
  - [GITHUB_TOKEN](https://docs.github.com/en/actions/concepts/security/github_token)
  - [Dependency caching](https://docs.github.com/en/actions/reference/workflows-and-actions/dependency-caching)
  - [Approving runs from forks](https://docs.github.com/en/actions/how-tos/manage-workflow-runs/approve-runs-from-forks)
  - [Repository roles](https://docs.github.com/en/organizations/managing-user-access-to-your-organizations-repositories/managing-repository-roles/repository-roles-for-an-organization)
- Renovate 44.205.2 source: `dist/modules/platform/github/{index,pr,user,graphql}.js`
- Repository settings: `gh api repos/Skycoder42/dart_test_tools/...` (read-only), 2026-11-07
