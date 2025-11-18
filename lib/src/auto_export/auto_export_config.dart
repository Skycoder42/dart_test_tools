// ignore_for_file: invalid_annotation_target for freezed
@internal
library;

import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:glob/glob.dart';

import 'yaml_serializable.dart';

part 'auto_export_config.freezed.dart';
part 'auto_export_config.g.dart';

@Freezed(fromJson: false, toJson: true)
sealed class AutoExportConfig with _$AutoExportConfig {
  @yamlSerializable
  const factory AutoExportConfig(ListOrValue<ExportTarget> exports) =
      _AutoExportConfig;

  factory AutoExportConfig.fromJson(Map<dynamic, dynamic>? json) {
    final anyNameOrExports = ListOrValue.fromJson(json!['exports'], (v) => v)
        .whereType<Map<dynamic, dynamic>>()
        .any((m) => m.containsKey('name') || m.containsKey('exports'));
    if (anyNameOrExports) {
      return _$AutoExportConfigFromJson(json);
    }

    final target = ExportTarget.fromJson({...json, 'name': ''});
    return AutoExportConfig(ListOrValue.value(target));
  }

  const AutoExportConfig._();

  void validate() {
    final keySet = <String>{};
    for (final target in exports) {
      if (!keySet.add(target.name)) {
        throw FormatException('Duplicate export target name: ${target.name}');
      }
    }
  }
}

@freezed
sealed class ExportTarget with _$ExportTarget {
  @yamlSerializable
  const factory ExportTarget({
    required String name,
    required ListOrValue<ExportDefinition> exports,
  }) = _ExportTarget;

  factory ExportTarget.fromJson(Map<dynamic, dynamic> json) =>
      _$ExportTargetFromJson(json);

  const ExportTarget._();
}

@Freezed(fromJson: false, toJson: false)
sealed class ExportDefinition with _$ExportDefinition {
  const factory ExportDefinition.glob(ExportPattern pattern) =
      GlobExportDefinition;

  @yamlSerializable
  const factory ExportDefinition.single({
    required Uri uri,
    ListOrValue<String>? show,
    ListOrValue<String>? hide,
    @JsonKey(name: 'if') ExportConfigurations? configurations,
  }) = SingleExportDefinition;

  factory ExportDefinition.fromJson(dynamic json) => switch (json) {
    String() => ExportDefinition.glob(ExportPattern.fromJson(json)),
    Map() => _$SingleExportDefinitionFromJson(json),
    _ => throw const FormatException(
      'Invalid export definition format! Must be either a string or a map.',
    ),
  };

  const ExportDefinition._();

  dynamic toJson() => switch (this) {
    GlobExportDefinition(:final pattern) => pattern.toJson(),
    final SingleExportDefinition d => _$SingleExportDefinitionToJson(d),
  };
}

@Freezed(fromJson: false, toJson: false)
sealed class ExportPattern with _$ExportPattern {
  const factory ExportPattern(Glob pattern, {@Default(false) bool negated}) =
      _ExportPattern;

  factory ExportPattern.fromJson(String json) {
    if (json.startsWith('!')) {
      return ExportPattern(
        Glob(json.substring(1), caseSensitive: true),
        negated: true,
      );
    } else {
      return ExportPattern(Glob(json, caseSensitive: true));
    }
  }

  const ExportPattern._();

  String toJson() => negated ? '!${pattern.pattern}' : pattern.pattern;
}

@Freezed(fromJson: false, toJson: false)
sealed class ExportConfigurations with _$ExportConfigurations {
  const factory ExportConfigurations(List<ExportConfiguration> configurations) =
      _ExportConfigurations;

  factory ExportConfigurations.fromJson(dynamic json) => switch (json) {
    Map() => ExportConfigurations([
      for (final MapEntry(:key, :value) in json.cast<String, String>().entries)
        ExportConfiguration(define: key, uri: Uri.parse(value)),
    ]),
    List() => ExportConfigurations([
      for (final value in json.cast<Map<dynamic, dynamic>>())
        ExportConfiguration.fromJson(value),
    ]),
    _ => throw const FormatException(
      'Invalid export configurations format! Must be either a map or a list.',
    ),
  };

  const ExportConfigurations._();

  dynamic toJson() => configurations.every((e) => e.equals == null)
      ? {for (final config in configurations) config.define: config.uri}
      : [for (final config in configurations) config.toJson()];
}

@freezed
sealed class ExportConfiguration with _$ExportConfiguration {
  @yamlSerializable
  const factory ExportConfiguration({
    required String define,
    String? equals,
    required Uri uri,
  }) = _ExportConfiguration;

  factory ExportConfiguration.fromJson(Map<dynamic, dynamic> json) =>
      _$ExportConfigurationFromJson(json);

  const ExportConfiguration._();
}
