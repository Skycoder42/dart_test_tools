@internal
library;

import 'package:freezed_annotation/freezed_annotation.dart';

part 'pkgbuild.freezed.dart';

@internal
@freezed
sealed class Pkgbuild with _$Pkgbuild {
  const factory({
    required String maintainer,
    required Map<String, PkgProperty> properties,
    required Map<String, PkgFunction> functions,
  }) = _Pkgbuild;

  const new _();

  String encode() =>
      '''
# Maintainer: $maintainer
${properties.encode()}

${functions.encode()}
''';
}

@internal
@freezed
sealed class PkgProperty with _$PkgProperty {
  const factory(Object? value) = _Single;

  const factory interpolate(String value) = _Interpolate;

  const factory list(
    List<PkgProperty> values, {
    @Default(true) bool skipEmpty,
    @Default(false) bool multiLine,
  }) = _List;

  factory literalList(
    List<String> values, {
    bool skipEmpty = true,
    bool multiLine = false,
  }) => PkgProperty.list(
    values.map(PkgProperty.new).toList(),
    skipEmpty: skipEmpty,
    multiLine: multiLine,
  );

  const new _();

  bool get isEmpty => switch (this) {
    _Single(:final value) => value == null,
    _List(:final values, :final skipEmpty) => skipEmpty && values.isEmpty,
    _ => false,
  };

  String encode({int width = 0}) => switch (this) {
    _Single(value: null) => '',
    _Single(:final String value) => "'$value'",
    _Single(:final value) => '$value',
    _Interpolate(:final value) => '"$value"',
    _List(:final values, multiLine: true) =>
      '(${_encode(values).join('\n${' ' * (width + 1)}')})',
    _List(:final values, multiLine: false) => '(${_encode(values).join(' ')})',
  };

  static Iterable<String> _encode(Iterable<PkgProperty> properties) =>
      properties.map((p) => p.encode());
}

@internal
extension PkgPropertyMapX on Map<String, PkgProperty> {
  String encode() => entries
      .map(
        (e) => e.value.isEmpty
            ? null
            : '${e.key}=${e.value.encode(width: e.key.length + 1)}',
      )
      .whereType<String>()
      .join('\n');
}

@internal
@freezed
sealed class PkgFunction with _$PkgFunction {
  const factory(List<String> commands) = _PkgFunction;

  const new _();

  String encode(String name) =>
      '''
$name() {
${commands.map((c) => '  $c').join('\n')}
}
''';
}

@internal
extension PkgFunctionMapX on Map<String, PkgFunction> {
  String encode() =>
      entries.map((entry) => entry.value.encode(entry.key)).join('\n');
}
