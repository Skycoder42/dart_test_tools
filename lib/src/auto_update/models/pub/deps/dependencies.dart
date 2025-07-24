import 'package:freezed_annotation/freezed_annotation.dart';

import 'dep_info.dart';
import 'executable_name.dart';
import 'sdk_info.dart';

part 'dependencies.freezed.dart';
part 'dependencies.g.dart';

@freezed
sealed class Dependencies with _$Dependencies {
  const factory Dependencies({
    required String root,
    required List<DepInfo> packages,
    required List<SdkInfo> sdks,
    @Default([]) List<ExecutableName> executables,
  }) = _Dependencies;

  factory Dependencies.fromJson(Map<String, dynamic> json) =>
      _$DependenciesFromJson(json);
}
