import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:pub_semver/pub_semver.dart';

import 'converters/version_converter.dart';

part 'pub_deps.freezed.dart';
part 'pub_deps.g.dart';

@freezed
sealed class PubDeps with _$PubDeps {
  const factory({required List<PubDepsPackage> packages}) = _PubDeps;

  factory fromJson(Map<String, dynamic> json) => _$PubDepsFromJson(json);
}

@freezed
sealed class PubDepsPackage with _$PubDepsPackage {
  @VersionConverter()
  const factory({
    required String name,
    required Version version,
    required String source,
  }) = _PubDepsPackage;

  factory fromJson(Map<String, dynamic> json) => _$PubDepsPackageFromJson(json);
}
