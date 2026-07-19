import 'package:meta/meta.dart';
import 'package:pub_semver/pub_semver.dart';

@internal
class NfpmVersion {
  final String version;
  final String? prerelease;
  final String? release;

  const NfpmVersion({required this.version, this.prerelease, this.release});
}

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
