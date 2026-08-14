import 'package:freezed_annotation/freezed_annotation.dart';

part 'secret.freezed.dart';
part 'secret.g.dart';

@freezed
sealed class Secret with _$Secret {
  const factory({
    required bool required,
    @JsonKey(includeIfNull: false) String? description,
  }) = _Secret;

  factory fromJson(Map<String, dynamic> json) => _$SecretFromJson(json);
}

typedef Secrets = Map<String, Secret>;
