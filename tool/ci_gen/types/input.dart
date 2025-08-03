// ignore_for_file: invalid_annotation_target

import 'dart:convert';

import 'package:freezed_annotation/freezed_annotation.dart';

part 'input.freezed.dart';
part 'input.g.dart';

enum Type { boolean, number, string }

@freezed
sealed class Input with _$Input {
  @Assert(
    'defaultValue == null || '
        '(identical(type, Type.boolean) && defaultValue is bool) || '
        '(identical(type, Type.number) && defaultValue is num) || '
        '(identical(type, Type.string) && defaultValue is String)',
    r'default must be a of type $type',
  )
  const factory Input({
    required Type type,
    required bool required,
    @JsonKey(name: 'default', includeIfNull: false) dynamic defaultValue,
    @JsonKey(includeIfNull: false) String? description,
    @JsonKey(includeIfNull: false) String? deprecationMessage,
  }) = _NormalInput;

  const factory Input.action({
    required bool required,
    @JsonKey(name: 'default', includeIfNull: false) String? defaultValue,
    required String? description,
    @JsonKey(includeIfNull: false) String? deprecationMessage,
  }) = _ActionInput;

  factory Input.json({
    required bool required,
    required dynamic defaultValue,
    String? description,
    String? deprecationMessage,
  }) => Input(
    type: Type.string,
    required: required,
    defaultValue: json.encode(defaultValue),
    description: description,
    deprecationMessage: deprecationMessage,
  );

  factory Input.fromJson(Map<String, dynamic> json) => _$InputFromJson(json);
}

typedef Inputs = Map<String, Input?>;
