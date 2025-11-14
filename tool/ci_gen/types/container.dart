// ignore_for_file: invalid_annotation_target for freezed

import 'package:freezed_annotation/freezed_annotation.dart';

part 'container.freezed.dart';
part 'container.g.dart';

@freezed
sealed class Container with _$Container {
  const factory Container({
    required String image,
    @JsonKey(includeIfNull: false) String? options,
  }) = _Container;

  factory Container.fromJson(Map<String, dynamic> json) =>
      _$ContainerFromJson(json);
}
