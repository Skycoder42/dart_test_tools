import 'package:freezed_annotation/freezed_annotation.dart';

import 'package_info.dart';

part 'outdated_info.freezed.dart';
part 'outdated_info.g.dart';

@freezed
@internal
sealed class OutdatedInfo with _$OutdatedInfo {
  const factory({required List<PackageInfo> packages}) = _OutdatedInfo;

  factory fromJson(Map<String, dynamic> json) => _$OutdatedInfoFromJson(json);
}
