// ignore_for_file: invalid_annotation_target for freezed

import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:pubspec_parse/pubspec_parse.dart';

part 'cask_options.freezed.dart';
part 'cask_options.g.dart';

@freezed
sealed class CaskOptions with _$CaskOptions {
  const factory CaskOptions({
    required Pubspec pubspec,
    required CaskPubspecOptions options,
    required AppInfoOptions appInfo,
  }) = _CaskOptions;
}

@freezed
sealed class AppInfoOptions with _$AppInfoOptions {
  const factory AppInfoOptions({
    @JsonKey(name: 'PRODUCT_BUNDLE_IDENTIFIER')
    required String productBundleIdentifier,
    @JsonKey(name: 'PRODUCT_NAME') required String productName,
  }) = _AppInfoOptions;

  factory AppInfoOptions.fromJson(Map<String, dynamic> json) =>
      _$AppInfoOptionsFromJson(json);
}

@internal
@freezed
sealed class CaskOptionsPubspecView with _$CaskOptionsPubspecView {
  @JsonSerializable(anyMap: true, checked: true)
  const factory CaskOptionsPubspecView({required CaskPubspecOptions cask}) =
      _CaskOptionsPubspecView;

  factory CaskOptionsPubspecView.fromJson(Map<String, dynamic> json) =>
      _$CaskOptionsPubspecViewFromJson(json);

  factory CaskOptionsPubspecView.fromYaml(Map<dynamic, dynamic>? map) =>
      _$CaskOptionsPubspecViewFromJson(map!);
}

@internal
@freezed
sealed class CaskPubspecOptions with _$CaskPubspecOptions {
  @JsonSerializable(anyMap: true, checked: true, disallowUnrecognizedKeys: true)
  const factory CaskPubspecOptions({
    String? caskName,
    required String downloadUrl,
    @Default(':catalina') String minMacosVersion,
    List<String>? zap,
  }) = _CaskPubspecOptions;

  factory CaskPubspecOptions.fromJson(Map<String, dynamic> json) =>
      _$CaskPubspecOptionsFromJson(json);
}
