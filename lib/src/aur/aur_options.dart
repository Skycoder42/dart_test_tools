// ignore_for_file: invalid_annotation_target for freezed

import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:pubspec_parse/pubspec_parse.dart';

part 'aur_options.freezed.dart';
part 'aur_options.g.dart';

@internal
@freezed
sealed class PubspecWithAur with _$PubspecWithAur {
  const factory PubspecWithAur({
    required Pubspec pubspec,
    required AurOptions aurOptions,
    required Map<String, String?> executables,
  }) = _PubspecWithAur;
}

@internal
@freezed
sealed class AurOptionsPubspecView with _$AurOptionsPubspecView {
  @JsonSerializable(anyMap: true, checked: true)
  const factory AurOptionsPubspecView({
    @JsonKey(required: true) required Map<String, String?> executables,
    @JsonKey(required: true) required AurOptions aur,
  }) = _AurOptionsPubspecView;

  factory AurOptionsPubspecView.fromJson(Map<String, dynamic> json) =>
      _$AurOptionsPubspecViewFromJson(json);

  factory AurOptionsPubspecView.fromYaml(Map<dynamic, dynamic>? map) =>
      AurOptionsPubspecView.fromJson(Map<String, dynamic>.from(map!));
}

@internal
@freezed
sealed class AurOptions with _$AurOptions {
  @JsonSerializable(anyMap: true, checked: true, disallowUnrecognizedKeys: true)
  const factory AurOptions({
    @JsonKey(required: true) required String maintainer,
    String? pkgname,
    int? epoch,
    @Default(1) int pkgrel,
    @Default('v') String tagPrefix,
    @Default('custom') String license,
    @Default([]) List<String> depends,
    String? sourcesDir,
    @Default('binaries') String binariesArchivePrefix,
    @Default([]) List<Source> extraSources,
    String? install,
    @Default([]) List<InstallTarget> files,
    @Default([]) List<String> backup,
    MakedebOptions? makedeb,
  }) = _AurOptions;

  factory AurOptions.fromJson(Map<String, dynamic> json) =>
      _$AurOptionsFromJson(json);
}

@internal
@freezed
sealed class Source with _$Source {
  @JsonSerializable(anyMap: true, checked: true, disallowUnrecognizedKeys: true)
  const factory Source({
    @JsonKey(required: true) required String name,
    @JsonKey(required: true) required Uri url,
  }) = _Source;

  factory Source.fromJson(Map<String, dynamic> json) => _$SourceFromJson(json);
}

@internal
@freezed
sealed class InstallTarget with _$InstallTarget {
  @JsonSerializable(anyMap: true, checked: true, disallowUnrecognizedKeys: true)
  const factory InstallTarget({
    @JsonKey(required: true) required String source,
    @JsonKey(required: true) required String target,
    @Default(644) int permissions,
    @Default(false) bool recursive,
  }) = _InstallTarget;

  factory InstallTarget.fromJson(Map<String, dynamic> json) =>
      _$InstallTargetFromJson(json);
}

@internal
@freezed
sealed class MakedebOptions with _$MakedebOptions {
  @JsonSerializable(anyMap: true, checked: true, disallowUnrecognizedKeys: true)
  const factory MakedebOptions({
    List<String>? depends,
    List<InstallTarget>? files,
    List<String>? backup,
  }) = _MakedebOptions;

  factory MakedebOptions.fromJson(Map<String, dynamic> json) =>
      _$MakedebOptionsFromJson(json);
}
