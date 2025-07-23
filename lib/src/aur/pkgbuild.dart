import 'package:freezed_annotation/freezed_annotation.dart';

part 'pkgbuild.freezed.dart';

@internal
@freezed
sealed class Pkgbuild with _$Pkgbuild {
  const factory Pkgbuild({
    required String maintainer,
    required Map<String, PkgProperty> properties,
    required Map<String, PkgFunction> functions,
  }) = _Pkgbuild;

  const Pkgbuild._();

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
  const factory PkgProperty(Object? value) = _Single;

  const factory PkgProperty.interpolate(String value) = _Interpolate;

  const factory PkgProperty.list(
    List<PkgProperty> values, {
    @Default(true) bool skipEmpty,
    @Default(false) bool multiLine,
  }) = _List;

  factory PkgProperty.literalList(
    List<String> values, {
    bool skipEmpty = true,
    bool multiLine = false,
  }) => PkgProperty.list(
    values.map(PkgProperty.new).toList(),
    skipEmpty: skipEmpty,
    multiLine: multiLine,
  );

  const PkgProperty._();

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
  const factory PkgFunction(List<String> commands) = _PkgFunction;

  const PkgFunction._();

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
