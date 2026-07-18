import 'package:meta/meta.dart';
import 'package:pub_semver/pub_semver.dart';

/// The nfpm version fields derived from a pub [Version].
@internal
class NfpmVersion {
  /// The `major.minor.patch` core version string.
  final String version;

  /// The nfpm `prerelease` field, or `null` if the version has none.
  final String? prerelease;

  /// The nfpm `release` field, or `null` if the version has no build number.
  final String? release;

  /// Default constructor.
  const NfpmVersion({required this.version, this.prerelease, this.release});
}

/// Converts a pub [version] into the [NfpmVersion] fields.
///
/// The pre-release identifier (e.g. `-dev.2`) maps to `prerelease` and the
/// build identifier (e.g. `+3`) maps to `release`, which preserves pub's
/// build-number ordering in the resulting package version.
///
/// Throws a [FormatException] if the build identifier contains characters that
/// cannot be represented as a package release.
@internal
NfpmVersion convertVersion(Version version) {
  final release = version.build.isEmpty ? null : version.build.join('.');
  if (release != null && !RegExp(r'^[A-Za-z0-9.]+$').hasMatch(release)) {
    throw FormatException(
      'Cannot convert build identifier "$release" to a package release. '
      'Only alphanumeric characters and dots are supported.',
    );
  }

  return NfpmVersion(
    version: '${version.major}.${version.minor}.${version.patch}',
    prerelease: version.preRelease.isEmpty
        ? null
        : version.preRelease.join('.'),
    release: release,
  );
}
