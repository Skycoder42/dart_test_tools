// ignore_for_file: invalid_annotation_target for freezed

import 'package:freezed_annotation/freezed_annotation.dart';

import '../../auto_export/yaml_serializable.dart';
import 'bump_level.dart';
import 'message_template.dart';
import 'renovate_upgrade.dart';

part 'bump_rule.freezed.dart';
part 'bump_rule.g.dart';

@internal
enum RenovateUpdateType() {
  major,
  minor,
  patch,
  pin,
  digest,
  pinDigest,
  lockFileMaintenance,
  rollback,
  bump,
  replacement,
}

@freezed
@internal
sealed class const BumpRule._() with _$BumpRule {
  @JsonSerializable(
    anyMap: true,
    fieldRename: .snake,
    checked: true,
    disallowUnrecognizedKeys: true,
  )
  const factory({
    @JsonKey(required: true) required ListOrValue<String> manager,
    @JsonKey(required: true) required ListOrValue<String> name,
    @Default(ListOrValue.list([])) ListOrValue<RenovateUpdateType> updateTypes,
    @Default(BumpLevel.patch) BumpLevel bump,
    @JsonKey(required: true) required MessageTemplate message,
  }) = _BumpRule;

  factory fromJson(Map<dynamic, dynamic> json) => _$BumpRuleFromJson(json);

  bool matches(RenovateUpgrade upgrade) =>
      manager.contains(upgrade.manager) &&
      name.contains(upgrade.depName) &&
      (updateTypes.isEmpty ||
          updateTypes.any((type) => type.name == upgrade.updateType));

  String get description => '${manager.join('|')}/${name.join('|')}';
}
