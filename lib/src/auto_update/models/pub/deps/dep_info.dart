import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:pub_semver/pub_semver.dart';

import '../../dependency_source.dart';
import '../dependency_kind.dart';
import '../version_converter.dart';

part 'dep_info.freezed.dart';
part 'dep_info.g.dart';

@internal
@freezed
sealed class DepInfo with _$DepInfo {
  @VersionConverter()
  const factory DepInfo({
    required String name,
    required Version version,
    required DependencyKind kind,
    required DependencySource source,
    @Default([]) List<String> dependencies,
    @Default([]) List<String> directDependencies,
    @Default([]) List<String> devDependencies,
  }) = _DepInfo;

  factory DepInfo.fromJson(Map<String, dynamic> json) =>
      _$DepInfoFromJson(json);
}
