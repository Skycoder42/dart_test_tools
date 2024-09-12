// ignore_for_file: invalid_annotation_target

import 'package:freezed_annotation/freezed_annotation.dart';

import 'analysis_options_ref.dart';

part 'analysis_options.freezed.dart';
part 'analysis_options.g.dart';

@freezed
class AnalysisOptions with _$AnalysisOptions {
  @JsonSerializable(
    anyMap: true,
    checked: true,
  )
  const factory AnalysisOptions({
    AnalysisOptionsRef? include,
    AnalysisOptionsAnalyzer? analyzer,
    AnalysisOptionsLinter? linter,
  }) = _AnalysisOptions;

  factory AnalysisOptions.fromJson(Map<String, dynamic> json) =>
      _$AnalysisOptionsFromJson(json);

  factory AnalysisOptions.fromYaml(Map<dynamic, dynamic>? map) =>
      AnalysisOptions.fromJson(Map<String, dynamic>.from(map!));
}

@freezed
class AnalysisOptionsAnalyzer with _$AnalysisOptionsAnalyzer {
  @JsonSerializable(
    anyMap: true,
    checked: true,
  )
  const factory AnalysisOptionsAnalyzer({
    @JsonKey(includeIfNull: false) List<String>? plugins,
  }) = _AnalysisOptionsAnalyzer;

  factory AnalysisOptionsAnalyzer.fromJson(Map<String, dynamic> json) =>
      _$AnalysisOptionsAnalyzerFromJson(json);
}

@freezed
class AnalysisOptionsLinter with _$AnalysisOptionsLinter {
  @JsonSerializable(
    anyMap: true,
    checked: true,
    disallowUnrecognizedKeys: true,
  )
  const factory AnalysisOptionsLinter({
    required dynamic rules,
  }) = _AnalysisOptionsLinter;

  factory AnalysisOptionsLinter.fromJson(Map<String, dynamic> json) =>
      _$AnalysisOptionsLinterFromJson(json);

  const AnalysisOptionsLinter._();

  Map<String, bool> get ruleMap {
    final dynamic rulesValue = rules;
    if (rulesValue == null) {
      return const {};
    } else if (rulesValue is List) {
      return Map.unmodifiable(<String, bool>{
        for (final rule in rulesValue.cast<String>()) rule: true,
      });
    } else if (rulesValue is Map) {
      return Map.unmodifiable(rulesValue.cast<String, bool>());
    } else {
      throw UnsupportedError('Cannot get rules from ${rulesValue.runtimeType}');
    }
  }

  List<String> get ruleList => ruleMap.keys.toList();
}
