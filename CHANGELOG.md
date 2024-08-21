# Changelog
All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [5.11.7] - 2024-08-21
### Changed
- Remove `document_ignores` lint

## [5.11.6] - 2024-08-19
### Changed
- Added support for shared source for ios/macos with version sync
- Updated dependencies
- Updated linter rules

## [5.11.5] - 2024-08-11
### Changed
- Updated dependencies
- Updated min required dart sdk to 3.5.0

### Fixed
- Fixed import reference

## [5.11.4] - 2024-07-11
### Changed
- Revert minisign workaround

### Fixed
- Remove leading zeros from build number

## [5.11.3] - 2024-06-16
### Changed
- Updated dependencies

### Fixed
- Applied workaround for minisign on windows

## [5.11.2] - 2024-06-10
### Fixed
- Fixed install files ignored in makedeb mode
- Fix missing await in cider plugin

## [5.11.1] - 2024-06-08
### Fixed
- fix pkgbuild generator

## [5.11.0] - 2024-05-24
### Added
- Improved generate-pkgbuild:
  - Added support for custom sources
  - Added support for installing directories

## [5.10.2+1] - 2024-05-17
### Fixed
- revert removed deprecations to stay compatible with analyzer 6.4

## [5.10.2] - 2024-05-17
### Changed
- Update min required dart sdk to 3.4.0
- Update dependencies

## [5.10.1] - 2024-04-22
### Fixed
- Fixed cask name generation

## [5.10.0] - 2024-04-22
### Added
- Added generate-cask tool

## [5.9.0] - 2024-04-15
### Added
- Added `flatpak-repo-init` tool to create or update a flatpak repository with metadata
- Added `export-xml-changelog` tool to convert the CHANGELOG.md into Release Information XML
- Added new custom\_lint rule `freezed_classes_must_be_sealed` that ensures freezed classes are always marked as `sealed`

### Changed
- Renamed binary tools to use `-` instead of `_`
  - `generate-build-number`
  - `generate-pkgbuild`
- Added `--env` parameter to `generate-build-number` to allow setting an environment variable instead of a an output
variable

## [5.8.1] - 2024-04-02
### Fixed
- Fix subdir handling

## [5.8.0] - 2024-03-29
### Changed
- add more makepkg options

## [5.7.0] - 2024-03-20
### Changed
- Refactored AUR packages to not build from source anymore

## [5.6.2] - 2024-02-24
### Changed
- Update min required dart sdk to 3.3.0
- Update dependencies

## [5.6.1] - 2024-02-04
### Changed
- Update dependencies

### Fixed
- Fix breaking change with `cider>=0.2.6`

## [5.6.0] - 2023-12-15
### Added
- Added `MockCallableX` generic mocks
  - Can be used as callbacks to test for correct callback invocation

### Changed
- Updated dependencies
- Update min required dart sdk to 3.2.0

## [5.5.0] - 2023-11-04
### Added
- added new linter rules to `strict.yaml`
  - [no\_self\_assignments](https://dart.dev/tools/linter-rules/no_self_assignments)
  - [no\_wildcard\_variable\_uses](https://dart.dev/tools/linter-rules/no_wildcard_variable_uses)

### Changed
- Updated dependencies

## [5.4.0] - 2023-09-20
### Added
- Added `Github.env.setOutput` to set output variables
- Added `HttpClient.getHeader` to get a HTTP header value

### Changed
- Updated dependencies
- Update min required dart sdk to 3.1.0

## [5.3.0] - 2023-08-08
### Added
- Added isRecord test matcher

### Changed
- Update dependencies

## [5.2.0] - 2023-07-20
### Added
- Add additional devtools for CI

## [5.1.3] - 2023-06-30
### Changed
- Update dependencies
- disable strip extension for makedeb

## [5.1.2+1] - 2023-06-22
### Changed
- Update dependencies

## [5.1.2] - 2023-06-12
### Changed
- Updated breaking dependencies
- SEMI-BREAKING: Refactor cider API extension to match the new cider APIs

## [5.1.1] - 2023-05-16
### Changed
- update dependencies

## [5.1.0] - 2023-05-11
### Changed
- Update minimal dart SDK to 3.0.0

## [5.0.2] - 2023-05-10
### Fixed
- Ensure src\_library\_not\_exported only runs for published packages

## [5.0.1] - 2023-05-08
### Fixed
- Remove experimental analyzer rules

## [5.0.0] - 2023-05-04
### Added
- Support for `custom_lint`. The `dart_test_tools:lint` has been refactored into
a custom\_lint plugin
- Added support for new experimental linter rules
- Added support for macos integration tests

### Changed
- Renamed `analysis_options.yaml` to `strict.yaml`
- Renamed `analysis_options_package.yaml` to `package.yaml`
- Updated dependencies

### Removed
- The `dart_test_tools:lint` as well corresponding library files have been removed
  - Instead, `custom_lint` should be used
- Removed Bitrise integration

## [4.9.0] - 2023-04-07
### Added
- Add makedeb support to pkgbuild generator

## [4.8.0] - 2023-01-19
### Added
- create docker workflow
- add [cider](https://pub.dev/packages/cider) version-sync plugin to sync version to secondary files
- add `cider` command that executes [cider](https://pub.dev/packages/cider), but with the version sync plugin enabled

### Changed
- use new service authentication for publishing to pub.dev (dart only for now)

## [4.7.0] - 2023-01-03
### Changed
- require the use of cider for release changelog generation

## [4.6.0] - 2022-12-04
### Changed
- Update dependencies
- Update minimum required dart version to 2.18.4
- Enable additional linter rules

## [4.5.3+1] - 2022-10-11
### Changed
- Update dependencies
- Update minimum required dart version to 2.18.2

## [4.5.3] - 2022-08-29
### Fixed
- Fix linting: Disabled following rules
  - `always_use_package_imports`
  - `avoid_classes_with_only_static_members`
  - `avoid_private_typedef_functions`

## [4.5.2] - 2022-08-27
### Fixed
- Fix linting: Ensure newly added base rules are not disable accidentally

## [4.5.1] - 2022-08-26
### Changed
- Improve linting, use lint package as base again

## [4.5.0] - 2022-08-18
### Changed
- let `generate_pkgbuild` print the names of the files that have been created
- Improve git handling in AUR build

## [4.4.1] - 2022-08-17
### Fixed
- Fix wrong path being copied to PKGBUILD

## [4.4.0] - 2022-08-17
### Changed
- rename `install` to `files` in AUR options
- Add `install` to AUR options to allow specifying an install script
- Remove comment lines from generated PKGBUILD
- Update to analyzer 4.6.0

## [4.3.0] - 2022-08-03
### Added
- Add `backup` and `testArgs` aur config options

## [4.2.3] - 2022-07-28
### Fixed
- Add `options=('!strip')` to generated PKGBUILD, as stripping dart executables will break them

## [4.2.2] - 2022-07-28
### Fixed
- Fix wrong generation of PKGBUILD license field

## [4.2.1] - 2022-07-26
### Fixed
- Fix command name

## [4.2.0] - 2022-07-26
### Changed
- Improved the `generate-pkgbuild` command, fixed some bugs

## [4.1.0] - 2022-07-26
### Changed
- Add the `generate-pkgbuild` command to the package
  - Generates a PKGBUILD for publishing an Arch Linux package from the pubspec.yaml
  - Added a new callable workflow, `aur.yml` that automatically publishes a dart
  package to the AUR

## [4.0.0] - 2022-06-18
### Changed
- Use the official `lints` package as base for linting
- Add even stricter linter rules

## [3.3.3] - 2022-06-18
### Changed
- Update all dependencies
- Allow custom arguments for extended linters build step via `extendedAnalyzerArgs`

## [3.3.2] - 2022-05-20
### Changed
- Update SDK requirement to 2.17.0 and update all dependencies

## [3.3.1] - 2022-03-26
### Fixed
- files that export other files are no longer reported as unexported, if they
do not re-export anything publicly visible

## [3.3.0] - 2022-03-21
### Added
- New test helper: `TestEnv.load()`, which loads an environment config from a
`'.env'` file, works in VM and JS contexts.
- Added `integrationTestEnvVars` secret to dart tests which writes the value
of the variable to a `.env` file for the integration tests.

### Changed
- updated dependencies

## [3.2.1] - 2022-03-02
### Changed
- Updated mocktail to 0.3.0 (major update)

## [3.2.0] - 2022-02-25
### Added
- Added github actions printer to lint command for better integration with GH actions

## [3.1.0] - 2022-02-23
### Added
- exported library `lint` to only import linters
- added testing helpers, exported as `test``
  - `testData` method to add tests with data
  - Extensions on `When` from `mocktail` for simpler stream and future return mocking
- `dart_test_tools` export exports all modules
- enable `public_member_api_docs` in `analysis_options_package.yaml` by default

### Changed
- Use newer location for credentials.json

### Fixed
- Allow older versions of analyzer to gain compatibility with flutter

## [3.0.0] - 2022-02-01
### Changed
- This a a complete rewrite of the public API of this package. Differences are
not listed, instead, only the new APIs are promoted here. The following things
have been added:
- Added new library with `Linter`s
  - `TestImportLinter`: Ensures test-files only import src files of the tested library
  - `LibExportLinter`: Ensures all sources with package-public members are exported somewhere
- Revised and modernized `lint` binary which can be used to run these analyzers on a dart package
- analysis\_options.yaml and analysis\_options\_package.yaml from 2.0.0 have been kept
- Generated CI/CD for dart and flutter has been kept
  - Now uses the `lint` binary for extended analysis

## [2.0.2] - 2022-01-21
### Changed
- Lower path required to be compatible with flutter

## [2.0.1] - 2022-01-21
### Changed
- Removed `public_member_api_docs` from package analysis options

## [2.0.0] - 2022-01-21
### Added
- analysis\_options.yaml and analysis\_options\_package.yaml for stricter defaults based on [lint](https://pub.dev/packages/lint)
- import analyser for library imports in tests

### Changed
- use `// ignore: test_library_import` for ignoring import scans

### Removed
- package library import analyzer
- old tools and other legacy stuff of the 1.0.0 release have been removed

## [1.0.0] - 2022-01-01
### Added
- Initial release

[5.11.7]: https://github.com/Skycoder42/dart_test_tools/compare/v5.11.6...v5.11.7
[5.11.6]: https://github.com/Skycoder42/dart_test_tools/compare/v5.11.5...v5.11.6
[5.11.5]: https://github.com/Skycoder42/dart_test_tools/compare/v5.11.4...v5.11.5
[5.11.4]: https://github.com/Skycoder42/dart_test_tools/compare/v5.11.3...v5.11.4
[5.11.3]: https://github.com/Skycoder42/dart_test_tools/compare/v5.11.2...v5.11.3
[5.11.2]: https://github.com/Skycoder42/dart_test_tools/compare/v5.11.1...v5.11.2
[5.11.1]: https://github.com/Skycoder42/dart_test_tools/compare/v5.11.0...v5.11.1
[5.11.0]: https://github.com/Skycoder42/dart_test_tools/compare/v5.10.2+1...v5.11.0
[5.10.2+1]: https://github.com/Skycoder42/dart_test_tools/compare/v5.10.2...v5.10.2+1
[5.10.2]: https://github.com/Skycoder42/dart_test_tools/compare/v5.10.1...v5.10.2
[5.10.1]: https://github.com/Skycoder42/dart_test_tools/compare/v5.10.0...v5.10.1
[5.10.0]: https://github.com/Skycoder42/dart_test_tools/compare/v5.9.0...v5.10.0
[5.9.0]: https://github.com/Skycoder42/dart_test_tools/compare/v5.8.1...v5.9.0
[5.8.1]: https://github.com/Skycoder42/dart_test_tools/compare/v5.8.0...v5.8.1
[5.8.0]: https://github.com/Skycoder42/dart_test_tools/compare/v5.7.0...v5.8.0
[5.7.0]: https://github.com/Skycoder42/dart_test_tools/compare/v5.6.2...v5.7.0
[5.6.2]: https://github.com/Skycoder42/dart_test_tools/compare/v5.6.1...v5.6.2
[5.6.1]: https://github.com/Skycoder42/dart_test_tools/compare/v5.6.0...v5.6.1
[5.6.0]: https://github.com/Skycoder42/dart_test_tools/compare/v5.5.0...v5.6.0
[5.5.0]: https://github.com/Skycoder42/dart_test_tools/compare/v5.4.0...v5.5.0
[5.4.0]: https://github.com/Skycoder42/dart_test_tools/compare/v5.3.0...v5.4.0
[5.3.0]: https://github.com/Skycoder42/dart_test_tools/compare/v5.2.0...v5.3.0
[5.2.0]: https://github.com/Skycoder42/dart_test_tools/compare/v5.1.3...v5.2.0
[5.1.3]: https://github.com/Skycoder42/dart_test_tools/compare/v5.1.2+1...v5.1.3
[5.1.2+1]: https://github.com/Skycoder42/dart_test_tools/compare/v5.1.2...v5.1.2+1
[5.1.2]: https://github.com/Skycoder42/dart_test_tools/compare/v5.1.1...v5.1.2
[5.1.1]: https://github.com/Skycoder42/dart_test_tools/compare/v5.1.0...v5.1.1
[5.1.0]: https://github.com/Skycoder42/dart_test_tools/compare/v5.0.2...v5.1.0
[5.0.2]: https://github.com/Skycoder42/dart_test_tools/compare/v5.0.1...v5.0.2
[5.0.1]: https://github.com/Skycoder42/dart_test_tools/compare/v5.0.0...v5.0.1
[5.0.0]: https://github.com/Skycoder42/dart_test_tools/compare/v4.9.0...v5.0.0
[4.9.0]: https://github.com/Skycoder42/dart_test_tools/compare/v4.8.0...v4.9.0
[4.8.0]: https://github.com/Skycoder42/dart_test_tools/compare/v4.7.0...v4.8.0
[4.7.0]: https://github.com/Skycoder42/dart_test_tools/compare/v4.6.0...v4.7.0
[4.6.0]: https://github.com/Skycoder42/dart_test_tools/compare/v4.5.3+1...v4.6.0
[4.5.3+1]: https://github.com/Skycoder42/dart_test_tools/compare/v4.5.3...v4.5.3+1
[4.5.3]: https://github.com/Skycoder42/dart_test_tools/compare/v4.5.2...v4.5.3
[4.5.2]: https://github.com/Skycoder42/dart_test_tools/compare/v4.5.1...v4.5.2
[4.5.1]: https://github.com/Skycoder42/dart_test_tools/compare/v4.5.0...v4.5.1
[4.5.0]: https://github.com/Skycoder42/dart_test_tools/compare/v4.4.1...v4.5.0
[4.4.1]: https://github.com/Skycoder42/dart_test_tools/compare/v4.4.0...v4.4.1
[4.4.0]: https://github.com/Skycoder42/dart_test_tools/compare/v4.3.0...v4.4.0
[4.3.0]: https://github.com/Skycoder42/dart_test_tools/compare/v4.2.3...v4.3.0
[4.2.3]: https://github.com/Skycoder42/dart_test_tools/compare/v4.2.2...v4.2.3
[4.2.2]: https://github.com/Skycoder42/dart_test_tools/compare/v4.2.1...v4.2.2
[4.2.1]: https://github.com/Skycoder42/dart_test_tools/compare/v4.2.0...v4.2.1
[4.2.0]: https://github.com/Skycoder42/dart_test_tools/compare/v4.1.0...v4.2.0
[4.1.0]: https://github.com/Skycoder42/dart_test_tools/compare/v4.0.0...v4.1.0
[4.0.0]: https://github.com/Skycoder42/dart_test_tools/compare/v3.3.3...v4.0.0
[3.3.3]: https://github.com/Skycoder42/dart_test_tools/compare/v3.3.2...v3.3.3
[3.3.2]: https://github.com/Skycoder42/dart_test_tools/compare/v3.3.1...v3.3.2
[3.3.1]: https://github.com/Skycoder42/dart_test_tools/compare/v3.3.0...v3.3.1
[3.3.0]: https://github.com/Skycoder42/dart_test_tools/compare/v3.2.1...v3.3.0
[3.2.1]: https://github.com/Skycoder42/dart_test_tools/compare/v3.2.0...v3.2.1
[3.2.0]: https://github.com/Skycoder42/dart_test_tools/compare/v3.1.0...v3.2.0
[3.1.0]: https://github.com/Skycoder42/dart_test_tools/compare/v3.0.0...v3.1.0
[3.0.0]: https://github.com/Skycoder42/dart_test_tools/compare/v2.0.2...v3.0.0
[2.0.2]: https://github.com/Skycoder42/dart_test_tools/compare/v2.0.1...v2.0.2
[2.0.1]: https://github.com/Skycoder42/dart_test_tools/compare/v2.0.0...v2.0.1
[2.0.0]: https://github.com/Skycoder42/dart_test_tools/compare/v1.0.0...v2.0.0
[1.0.0]: https://github.com/Skycoder42/dart_test_tools/releases/tag/v1.0.0
