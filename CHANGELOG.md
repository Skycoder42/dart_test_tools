# Changelog
All notable changes to this project will be documented in this file.

The format is based on Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## 4.2.0
### Changed
- Improved the `generate-pkgbuild` command, fixed some bugs

## 4.1.0
### Changed
- Add the `generate-pkgbuild` command to the package
  - Generates a PKGBUILD for publishing an Arch Linux package from the pubspec.yaml
  - Added a new callable workflow, `aur.yml` that automatically publishes a dart
    package to the AUR

## 4.0.0
### Changed
- Use the official `lints` package as base for linting
- Add even stricter linter rules

## 3.3.3
### Changed
- Update all dependencies
- Allow custom arguments for extended linters build step via `extendedAnalyzerArgs`

## 3.3.2
### Changed
- Update SDK requirement to 2.17.0 and update all dependencies

## 3.3.1
### Fixed
- files that export other files are no longer reported as unexported, if they
do not re-export anything publicly visible

## 3.3.0
### Added
- New test helper: `TestEnv.load()`, which loads an environment config from a
`'.env'` file, works in VM and JS contexts.
- Added `integrationTestEnvVars` secret to dart tests which writes the value
of the variable to a `.env` file for the integration tests.
### Changed
- updated dependencies
### Deprecated
### Removed
### Fixed
### Security


## 3.2.1
### Changed
- Updated mocktail to 0.3.0 (major update)

## 3.2.0
### Added
- Added github actions printer to lint command for better integration with GH actions

## 3.1.0
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

## 3.0.0
This a a complete rewrite of the public API of this package. Differences are
not listed, instead, only the new APIs are promoted here. The following things
have been added:

- Added new library with `Linter`s
  - `TestImportLinter`: Ensures test-files only import src files of the tested library
  - `LibExportLinter`: Ensures all sources with package-public members are exported somewhere
- Revised and modernized `lint` binary which can be used to run these analyzers on a dart package
- analysis_options.yaml and analysis_options_package.yaml from 2.0.0 have been kept
- Generated CI/CD for dart and flutter has been kept
  - Now uses the `lint` binary for extended analysis

## 2.0.2
### Changed
- Lower path required to be compatible with flutter

## 2.0.1
### Changed
- Removed `public_member_api_docs` from package analysis options

## 2.0.0
### Removed
- old tools and other legacy stuff of the 1.0.0 release have been removed

## 2.0.0-test.3
### Changed
- use `// ignore: test_library_import` for ignoring import scans

## 2.0.0-test.2] -2022-01-17
### Added
- analysis_options.yaml and analysis_options_package.yaml for stricter defaults based on lint](https://pub.dev/packages/lint)
- import analyser for library imports in tests
### Removed
- package library import analyzer

## 2.0.0-test.1
- Test-Release. Do not use yet

## 1.0.0
- Initial release

## Unreleased
### Added
### Changed
### Deprecated
### Removed
### Fixed
### Security
