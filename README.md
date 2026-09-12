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
| `dart-test-tools-auto-update` | Run a new dependency update, or pick up the one open on `automatic-dependency-updates`, mirroring the shared auto-update workflow locally. |
| `dart-test-tools-cli-help` | Answer questions about the command line tools in `bin/` by running them with `--help`. |

To add a new skill, scaffold it with `dart run skills@ create` — the directory
name must be prefixed with `dart-test-tools-`.
