import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:pub_semver/pub_semver.dart';

import '../version_converter.dart';

part 'version_info.freezed.dart';
part 'version_info.g.dart';

@Freezed(toStringOverride: false)
@internal
sealed class VersionInfo with _$VersionInfo {
  @VersionConverter()
  const factory({required Version version, bool? nullSafety}) = _VersionInfo;

  factory fromJson(Map<String, dynamic> json) => _$VersionInfoFromJson(json);

  const new _();

  @override
  String toString() => switch (nullSafety) {
    true || null => version.toString(),
    false => '$version (not null safe)',
  };
}
