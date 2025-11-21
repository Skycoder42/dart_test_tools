// ignore_for_file: invalid_annotation_target for freezed

import 'dart:collection';

import 'package:freezed_annotation/freezed_annotation.dart';

import 'analysis_options_ref.dart';

part 'analysis_options.freezed.dart';
part 'analysis_options.g.dart';

enum DiagnosticLevel { error, warning, info, ignore }

@freezed
sealed class AnalysisOptions with _$AnalysisOptions {
  @JsonSerializable(anyMap: true, checked: true)
  const factory AnalysisOptions({
    @JsonKey(includeIfNull: false) ListOrValue<AnalysisOptionsRef>? include,
    @JsonKey(includeIfNull: false) Map<String, dynamic>? plugins,
    @JsonKey(includeIfNull: false) AnalysisOptionsAnalyzer? analyzer,
    @JsonKey(includeIfNull: false) AnalysisOptionsLinter? linter,
  }) = _AnalysisOptions;

  factory AnalysisOptions.fromJson(Map<String, dynamic> json) =>
      _$AnalysisOptionsFromJson(json);

  factory AnalysisOptions.fromYaml(Map<dynamic, dynamic>? map) =>
      AnalysisOptions.fromJson(Map<String, dynamic>.from(map!));
}

@freezed
sealed class AnalysisOptionsAnalyzer with _$AnalysisOptionsAnalyzer {
  @JsonSerializable(anyMap: true, checked: true)
  const factory AnalysisOptionsAnalyzer({
    @JsonKey(includeIfNull: false) Map<String, dynamic>? language,
    @JsonKey(includeIfNull: false) List<String>? exclude,
    @JsonKey(includeIfNull: false) Map<String, DiagnosticLevel>? errors,
  }) = _AnalysisOptionsAnalyzer;

  factory AnalysisOptionsAnalyzer.fromJson(Map<String, dynamic> json) =>
      _$AnalysisOptionsAnalyzerFromJson(json);
}

@freezed
sealed class AnalysisOptionsLinter with _$AnalysisOptionsLinter {
  @JsonSerializable(anyMap: true, checked: true, disallowUnrecognizedKeys: true)
  const factory AnalysisOptionsLinter({required dynamic rules}) =
      _AnalysisOptionsLinter;

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

@Freezed(fromJson: false, toJson: false)
sealed class ListOrValue<T>
    with _$ListOrValue<T>, ListMixin<T>, _UnmodifiableListMixin<T> {
  const factory ListOrValue.list(List<T> list) = _List;
  const factory ListOrValue.value(T value) = _ListValue;

  factory ListOrValue.fromJson(
    dynamic json,
    T Function(dynamic json) fromJsonT,
  ) {
    if (_implements<T, List<dynamic>>() && json is List) {
      final allChildrenAreLists = json.every((e) => e is List);
      return allChildrenAreLists
          ? ListOrValue.list(json.map(fromJsonT).toList())
          : ListOrValue.value(fromJsonT(json));
    } else {
      return json is List
          ? ListOrValue.list(json.map(fromJsonT).toList())
          : ListOrValue.value(fromJsonT(json));
    }
  }

  const ListOrValue._();

  bool get isList => switch (this) {
    _List() => true,
    _ListValue() => false,
  };

  @override
  int get length => switch (this) {
    _List(list: List(:final length)) => length,
    _ListValue() => 1,
  };

  @override
  T operator [](int index) => switch (this) {
    _List(:final list) => list[index],
    _ListValue(:final value) when index == 0 => value,
    _ListValue(:final value) => throw RangeError.index(index, [value]),
  };

  @override
  String toString() => switch (this) {
    _List(:final list) => list.toString(),
    _ListValue(:final value) => value.toString(),
  };

  dynamic toJson(dynamic Function(T value) toJsonT) => switch (this) {
    _List(:final list) => list.map(toJsonT).toList(),
    _ListValue(:final value) => toJsonT(value),
  };
}

mixin _UnmodifiableListMixin<T> on ListMixin<T> {
  @override
  set length(int length) => throw UnsupportedError(
    'Cannot change the length of an unmodifiable list',
  );

  @override
  void operator []=(int index, T value) =>
      throw UnsupportedError('Cannot modify an unmodifiable list');
}

bool _implements<TDerived, TBase>() => <TDerived>[] is List<TBase>;
