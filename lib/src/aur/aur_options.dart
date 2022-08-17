// ignore_for_file: invalid_annotation_target

import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:pubspec_parse/pubspec_parse.dart';

part 'aur_options.freezed.dart';
part 'aur_options.g.dart';

@internal
@freezed
class PubspecWithAur with _$PubspecWithAur {
  const factory PubspecWithAur({
    required Pubspec pubspec,
    required AurOptions aurOptions,
    required Map<String, String?> executables,
  }) = _PubspecWithAur;
}

@internal
@freezed
class AurOptionsPubspecView with _$AurOptionsPubspecView {
  @JsonSerializable(
    anyMap: true,
    checked: true,
  )
  const factory AurOptionsPubspecView({
    required Map<String, String?> executables,
    required AurOptions aur,
  }) = _AurOptionsPubspecView;

  factory AurOptionsPubspecView.fromJson(Map<String, dynamic> json) =>
      _$AurOptionsPubspecViewFromJson(json);

  factory AurOptionsPubspecView.fromYaml(Map? map) =>
      AurOptionsPubspecView.fromJson(Map<String, dynamic>.from(map!));
}

@internal
@freezed
class AurOptions with _$AurOptions {
  @JsonSerializable(
    anyMap: true,
    checked: true,
    disallowUnrecognizedKeys: true,
  )
  const factory AurOptions({
    required String maintainer,
    String? pkgname,
    int? epoch,
    @Default(1) int pkgrel,
    @Default('custom') String license,
    @Default(<String>[]) List<String> depends,
    String? testArgs,
    String? install,
    @Default(<InstallTarget>[]) List<InstallTarget> files,
    @Default(<String>[]) List<String> backup,
  }) = _AurOptions;

  factory AurOptions.fromJson(Map<String, dynamic> json) =>
      _$AurOptionsFromJson(json);
}

@internal
@freezed
class InstallTarget with _$InstallTarget {
  @JsonSerializable(
    anyMap: true,
    checked: true,
    disallowUnrecognizedKeys: true,
  )
  const factory InstallTarget({
    required String source,
    required String target,
    @Default(644) int permissions,
  }) = _InstallTarget;

  factory InstallTarget.fromJson(Map<String, dynamic> json) =>
      _$InstallTargetFromJson(json);
}
