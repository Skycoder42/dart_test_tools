A sample command-line application with an entrypoint in `bin/`, library code
in `lib/`, and example unit test in `test/`.

## AI agent skills

This package bundles [agent skills](https://dart.dev/blog/skills-cli-1-0-bundle-and-distribute-ai-agent-skills-for-your-packages)
under `skills/`. Projects that depend on `dart_test_tools` can install them into
their agent with:

```sh
dart run skills@ get dart_test_tools
```

| Skill | Purpose |
| --- | --- |
| `dart-test-tools-renovate-fix` | Check out a red Renovate pull request, re-run its post-upgrade step locally, validate the package the way CI does and help fix it. |
| `dart-test-tools-native-update` | Regenerate the native platform projects of a flutter app from the current Flutter templates, keep the template updates and restore the project's own identifiers and customisations. |
| `dart-test-tools-cli-help` | Answer questions about the command line tools in `bin/` by running them with `--help`. |

To add a new skill, scaffold it with `dart run skills@ create` — the directory
name must be prefixed with `dart-test-tools-`.

## Dependency updates with Renovate

Dependencies and SDK constraints are updated by self-hosted Renovate, run weekly by the
reusable `renovate.yml` workflow with the job's own `GITHUB_TOKEN`. All updates of a
week land in one pull request by `github-actions[bot]`. Its single commit also contains
the resolved lockfile, analyzer plugin pins, build_runner output, formatting,
`dart fix` and a changelog entry with a patch release. Your CI checks the pull request,
and a finish job at its end merges it when CI is green.

### Setting up a repository

These steps also migrate a repository that used the former `auto-update.yml` workflow.

1. In the repository settings, enable *Actions → General → Allow GitHub Actions to
   create and approve pull requests*.
2. Replace the caller of `auto-update.yml` (if any) with
   `.github/workflows/renovate.yml`:

   ```yaml
   name: Automatic dependency updates

   on:
     workflow_dispatch:
     schedule:
       - cron: "15 3 * * 1"
     issues:
       types:
         - edited

   jobs:
     renovate:
       name: Renovate
       uses: Skycoder42/dart_test_tools/.github/workflows/renovate.yml@main
       permissions:
         contents: write
         pull-requests: write
         issues: write
         statuses: write
   ```

   The `issues` trigger runs Renovate as soon as you tick a checkbox in the Dependency
   Dashboard issue. Inputs: `flutterSdkChannel` (default `stable`) and `flutterCompat`
   (default `true`: no dependency versions beyond the ones the Flutter SDK pins).
3. Add a `renovate.json` with one of the two presets:

   ```json
   {
     "$schema": "https://docs.renovatebot.com/renovate-schema.json",
     "extends": ["github>Skycoder42/dart_test_tools//renovate/library"]
   }
   ```

   - `library` — for packages without a committed `pubspec.lock`. Minor and patch
     updates only, but lower bounds are raised. Majors (and minors of `0.x`
     dependencies) wait for approval in the Dependency Dashboard and then get their
     own pull request.
   - `application` — for repositories with a committed `pubspec.lock`. All updates,
     majors included, plus a full `pub upgrade`.

   Pub workspaces are supported; Renovate finds every member on its own.
4. Add the finish job as the last job of your CI workflow, and make sure the workflow
   has a `workflow_dispatch` trigger:

   ```yaml
   on:
     workflow_dispatch:
     # ...

   jobs:
     # ...
     renovate:
       name: Renovate
       needs:
         - ci # every job of the workflow
       if: ${{ !cancelled() }}
       uses: Skycoder42/dart_test_tools/.github/workflows/renovate-finish.yml@main
       permissions:
         contents: write
         pull-requests: write
         actions: write
       with:
         needs: ${{ toJSON(needs) }}
   ```

   The job only acts on pull requests opened by Renovate. On green CI it merges the
   pull request (`mergeMethod`, default `squash`), but only the commit whose CI run was
   approved. Then it dispatches the CI workflow on the default branch: a merge made with
   `GITHUB_TOKEN` triggers no `push` run, so without the dispatch nothing would be
   released. Set `dispatchWorkflow` to dispatch a different workflow. On red CI, or when
   the merge fails, it comments on the pull request and mentions the repository owner.
5. Remove the `pub` entry from `.github/dependabot.yml`. Keep `github-actions`; security
   alerts stay with Dependabot in the repository settings.
6. Recommended: a ruleset on the default branch that requires pull requests and your
   status checks, but **no approving reviews**. A required review blocks the finish job's
   merge unless you also approve the pull request itself. Protect release tags with a
   tag ruleset and publishing workflows with an environment approval.

A Dependency Dashboard issue left over from an earlier Renovate setup under another
identity (an app, a token) is not reused — Renovate opens a new one. Close the old one by
hand.

### Day-to-day

1. Renovate opens the pull request and requests your review, so you get a notification.
2. Look at the diff, then *Approve workflows to run* — every push to a Renovate branch
   needs this approval before CI runs, also from the GitHub mobile app.
3. Green CI: the pull request is merged and released automatically. Red CI: you get a
   comment with a mention. The `dart-test-tools-renovate-fix` skill reproduces and
   repairs it locally.

Renovate does not rebase its pull request when the default branch moves, only on
conflicts. After a fix landed on the default branch, tick the rebase checkbox in the
pull request and run the Renovate workflow by hand (or wait for the schedule), then
approve the new runs. If you push a fix onto the Renovate branch instead, CI runs without
approval and the pull request is merged when green. Renovate stops updating an edited
branch; ticking the rebase checkbox rebuilds it and drops your commit.

### Customising

Your own `packageRules` in `renovate.json` are applied after the preset's. Use them to
ignore, pin or delay pub packages, or to move some of them into their own group. Keep in
mind:

- Other managers you enable (`enabledManagers`) put their updates into the same
  `renovate/all` branch. The post-upgrade step ignores them, so a pull request with only
  such updates gets no changelog entry and no version bump.
- Your own `postUpgradeTasks` are refused: the workflow only allows Renovate to run the
  post-upgrade step of dart_test_tools.
- Do not set `automerge` (the finish job merges), `schedule` (the caller's cron decides —
  both together can turn runs into no-ops) or `reviewers` (the workflow sets them).
- Do not add rules for the `dart-version` or `flutter-version` datasources that change
  `versioning`, `allowedVersions` or `overrideDatasource`. They would bring back Dart
  patch versions that never shipped with Flutter, or bare-version SDK constraints.
- Every pub group gets its own pull request with its own patch release. Once one is
  merged, the others conflict on `CHANGELOG.md` and the version, Renovate rebuilds them,
  and they need a new approval.
