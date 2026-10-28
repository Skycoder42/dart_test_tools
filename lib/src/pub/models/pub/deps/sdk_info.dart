import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:pub_semver/pub_semver.dart';

import '../version_converter.dart';

part 'sdk_info.freezed.dart';
part 'sdk_info.g.dart';

@freezed
sealed class SdkInfo with _$SdkInfo {
  @VersionConverter()
  const factory({required String name, required Version version}) = _SdkInfo;

  factory fromJson(Map<String, dynamic> json) => _$SdkInfoFromJson(json);
}
