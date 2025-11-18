@internal
library;

import 'dart:collection';

import 'package:freezed_annotation/freezed_annotation.dart';

part 'yaml_serializable.freezed.dart';

bool _implements<TDerived, TBase>() => <TDerived>[] is List<TBase>;

const yamlSerializable = JsonSerializable(
  includeIfNull: false,
  anyMap: true,
  explicitToJson: true,
);

@Freezed(fromJson: false, toJson: false)
sealed class ListOrValue<T>
    with _$ListOrValue<T>, ListMixin<T>, _UnmodifiableListMixin<T> {
  const factory ListOrValue.list(List<T> list) = _List;
  const factory ListOrValue.value(T value) = _ListValue;

  factory ListOrValue.fromJson(
    dynamic json,
    T Function(dynamic json) fromJsonT,
  ) {
    if (_implements<T, List<dynamic>>() && json is List) {
      final allChildrenAreLists = json.every((e) => e is List);
      return allChildrenAreLists
          ? ListOrValue.list(json.map(fromJsonT).toList())
          : ListOrValue.value(fromJsonT(json));
    } else {
      return json is List
          ? ListOrValue.list(json.map(fromJsonT).toList())
          : ListOrValue.value(fromJsonT(json));
    }
  }

  const ListOrValue._();

  bool get isList => switch (this) {
    _List() => true,
    _ListValue() => false,
  };

  @override
  int get length => switch (this) {
    _List(list: List(:final length)) => length,
    _ListValue() => 1,
  };

  @override
  T operator [](int index) => switch (this) {
    _List(:final list) => list[index],
    _ListValue(:final value) when index == 0 => value,
    _ListValue(:final value) => throw RangeError.index(index, [value]),
  };

  @override
  String toString() => switch (this) {
    _List(:final list) => list.toString(),
    _ListValue(:final value) => value.toString(),
  };

  dynamic toJson(dynamic Function(T value) toJsonT) => switch (this) {
    _List(:final list) => list.map(toJsonT).toList(),
    _ListValue(:final value) => toJsonT(value),
  };
}

mixin _UnmodifiableListMixin<T> on ListMixin<T> {
  @override
  set length(int length) => throw UnsupportedError(
    'Cannot change the length of an unmodifiable list',
  );

  @override
  void operator []=(int index, T value) =>
      throw UnsupportedError('Cannot modify an unmodifiable list');
}
