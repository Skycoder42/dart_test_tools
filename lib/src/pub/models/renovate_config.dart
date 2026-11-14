// ignore_for_file: invalid_annotation_target for freezed

import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:yaml/yaml.dart';

import '../../auto_export/yaml_serializable.dart';

part 'renovate_config.freezed.dart';
part 'renovate_config.g.dart';

@freezed
sealed class RenovateConfig with _$RenovateConfig {
  @JsonSerializable(
    anyMap: true,
    fieldRename: .snake,
    checked: true,
    disallowUnrecognizedKeys: true,
  )
  const factory({
    @Default(ListOrValue.list([])) ListOrValue<String> preBuildExtraManagers,
    String? preBuildCommand,
  }) = _RenovateConfig;

  factory fromYaml(YamlMap yaml) => _$RenovateConfigFromJson(yaml);

  factory fromJson(Map<String, dynamic> json) => _$RenovateConfigFromJson(json);
}
