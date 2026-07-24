# CLAUDE.md

## Tooling

- Use the `dart` MCP server for Dart tasks instead of shelling out to the `dart` CLI.
  In particular, use `mcp__dart__analyze_files` for analysis rather than `dart analyze`.

## Generated files

- The GitHub Actions workflows in `.github/workflows/*.yml` are **generated** from
  the Dart sources under `tool/ci_gen/`. Never edit the `.yml` files directly — they
  will be overwritten. Make changes in the corresponding `tool/ci_gen/**` source, then
  regenerate with `dart run tool/ci_gen.dart`.
- Similarly, linter configs are generated via `tool/linter_gen.dart`.
