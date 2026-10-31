import 'package:freezed_annotation/freezed_annotation.dart';

part 'renovate_upgrade.freezed.dart';
part 'renovate_upgrade.g.dart';

String? _emptyAsNull(String? value) =>
    value == null || value.isEmpty ? null : value;

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
  }) = _RenovateUpgrade;

  factory fromJson(Map<String, dynamic> json) =>
      _$RenovateUpgradeFromJson(json);

  bool get isSdkUpgrade => _sdkKeys.containsKey(depName);

  String get sdkKey =>
      _sdkKeys[depName] ??
      (throw StateError('$depName is not an SDK dependency'));
}
