import 'package:freezed_annotation/freezed_annotation.dart';

import '../dependency_kind.dart';
import 'version_info.dart';

part 'package_info.freezed.dart';
part 'package_info.g.dart';

@Freezed(toStringOverride: false)
@internal
sealed class PackageInfo with _$PackageInfo {
  const factory PackageInfo({
    required String package,
    required DependencyKind kind,
    @Default(false) bool isDiscontinued,
    @Default(false) bool isCurrentRetracted,
    @Default(false) bool isCurrentAffectedByAdvisory,
    VersionInfo? current,
    VersionInfo? upgradable,
    VersionInfo? resolvable,
    VersionInfo? latest,
  }) = _PackageInfo;

  factory PackageInfo.fromJson(Map<String, dynamic> json) =>
      _$PackageInfoFromJson(json);

  const PackageInfo._();

  @override
  String toString() {
    final sb = StringBuffer();
    switch (kind) {
      case DependencyKind.direct:
        break;
      case DependencyKind.transitive:
        sb.write('transitive:');
      case DependencyKind.dev:
        sb.write('dev:');
      case DependencyKind.root:
        sb.write('root:');
    }
    sb.write(package);

    if (isDiscontinued) {
      sb.write('[discontinued]');
    }
    if (isCurrentRetracted) {
      sb.write('[retracted]');
    }
    if (isCurrentAffectedByAdvisory) {
      sb.write('[vulnerable]');
    }

    sb
      ..write('@')
      ..write(current);

    return sb.toString();
  }
}
