import 'package:freezed_annotation/freezed_annotation.dart';

part 'renovate_upgrade.freezed.dart';
part 'renovate_upgrade.g.dart';

String? _emptyAsNull(Object? value) => switch (value) {
  null || '' => null,
  final String value => value,
  _ => value.toString(),
};

@freezed
@internal
sealed class const RenovateUpgrade._() with _$RenovateUpgrade {
  static const _sdkKeys = {'dart': 'sdk', 'flutter': 'flutter'};

  const factory({
    required String manager,
    required String depName,
    required String packageFile,
    @JsonKey(fromJson: _emptyAsNull) String? depType,
    @JsonKey(fromJson: _emptyAsNull) String? currentValue,
    @JsonKey(fromJson: _emptyAsNull) String? newValue,
    @JsonKey(fromJson: _emptyAsNull) String? updateType,
    @JsonKey(fromJson: _emptyAsNull) String? currentVersion,
    @JsonKey(fromJson: _emptyAsNull) String? newVersion,
    @JsonKey(fromJson: _emptyAsNull) String? currentDigest,
    @JsonKey(fromJson: _emptyAsNull) String? newDigest,
    @JsonKey(fromJson: _emptyAsNull) String? newDigestShort,
    @JsonKey(fromJson: _emptyAsNull) String? packageName,
    @JsonKey(fromJson: _emptyAsNull) String? datasource,
    @JsonKey(fromJson: _emptyAsNull) String? releaseTimestamp,
  }) = _RenovateUpgrade;

  factory fromJson(Map<String, dynamic> json) =>
      _$RenovateUpgradeFromJson(json);

  bool get isSdkUpgrade => _sdkKeys.containsKey(depName);

  String get sdkKey =>
      _sdkKeys[depName] ??
      (throw StateError('$depName is not an SDK dependency'));
}
