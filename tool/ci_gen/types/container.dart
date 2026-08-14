import 'package:freezed_annotation/freezed_annotation.dart';

part 'container.freezed.dart';
part 'container.g.dart';

@freezed
sealed class Container with _$Container {
  const factory({
    required String image,
    @JsonKey(includeIfNull: false) String? options,
  }) = _Container;

  factory fromJson(Map<String, dynamic> json) => _$ContainerFromJson(json);
}
