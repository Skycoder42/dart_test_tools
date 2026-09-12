---
name: dart-test-tools-cli-help
description: >-
  Use when the user asks what a dart_test_tools command line tool does, which
  options or flags it accepts, or which tools the package ships at all. Answers
  by invoking the tool with --help instead of guessing.
license: BSD-3-Clause
user-invocable: true
argument-hint: "[tool]"
allowed-tools:
  - Bash(dart run dart_test_tools:*)
---

# dart_test_tools CLI help

`dart_test_tools` ships a set of command line tools in its `bin/` directory.
Never describe their options from memory — the flags change between versions.
Run the tool with `--help` and answer from its actual output.

## Instructions

1. Pick the tool the user is asking about from the table below. If this skill
   was invoked with an argument, that argument is the tool name. If the question
   is about the package in general ("what can dart_test_tools do?"), present the
   table and offer to run `--help` for a specific tool.
2. Run it with `--help`:

   ```sh
   dart run dart_test_tools:<tool> --help
   ```

   For example:

   ```sh
   dart run dart_test_tools:auto_update --help
   ```

3. Answer using the printed usage text. Quote the relevant options verbatim
   rather than paraphrasing flag names or defaults.
4. Only run `--help`. Do not invoke a tool with real arguments to find out what
   it does — several of them write files, bump versions or push changes.

## Available tools

| Tool | Purpose |
| --- | --- |
| `auto_export` | Generate a library export file from `lib/src/`, optionally driven by `lib/exports.yaml`. |
| `auto_update` | Update dependencies and, optionally, create a changelog entry and version bump. |
| `cider` | The `cider` CLI plus an extra `version-sync` command. |
| `export_xml_changelog` | Export the `CHANGELOG.md` into an XML release description. |
| `flatpak_repo_init` | Initialize a GPG signed flatpak repository. |
| `generate_build_number` | Derive a numeric build number from the pubspec version. |
| `generate_cask` | Generate a Homebrew cask for a macOS app bundle. |
| `generate_nfpm` | Generate an `nfpm.yaml` for Linux package builds. |
| `generate_pkgbuild` | Generate an Arch Linux `PKGBUILD`. |

The table is a routing aid, not a substitute for `--help`. The authoritative
description of every option is what the tool prints.

## Notes

- `cider` is a command runner: `dart run dart_test_tools:cider --help` lists the
  commands, and `dart run dart_test_tools:cider help version-sync` describes a
  single one.
- The tools must be run from the package that depends on `dart_test_tools`. Most
  of them act on the current working directory and expect a `pubspec.yaml`
  there.
