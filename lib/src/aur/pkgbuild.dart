import 'package:freezed_annotation/freezed_annotation.dart';

part 'pkgbuild.freezed.dart';

@internal
@freezed
class Pkgbuild with _$Pkgbuild {
  const factory Pkgbuild({
    required String maintainer,
    required Map<String, PkgProperty> properties,
    required Map<String, PkgFunction> functions,
  }) = _Pkgbuild;
  const Pkgbuild._();

  String encode() => '''
# Maintainer: $maintainer
${properties.encode()}

${functions.encode()}
''';
}

@internal
@freezed
class PkgProperty with _$PkgProperty {
  const factory PkgProperty(Object? value) = _Single;
  const PkgProperty._();
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

  bool get isEmpty => maybeWhen(
    (value) => value == null,
    list: (values, skipEmpty, _) => skipEmpty && values.isEmpty,
    orElse: () => false,
  );

  String encode({int width = 0}) => when(
    (value) {
      if (value == null) {
        return '';
      } else if (value is String) {
        return "'$value'";
      } else {
        return '$value';
      }
    },
    interpolate: (value) => '"$value"',
    list: (props, skipEmpty, multiline) {
      final encodedProps = props.map((p) => p.encode());
      return multiline
          ? '(${encodedProps.join('\n${' ' * (width + 1)}')})'
          : '(${encodedProps.join(' ')})';
    },
  );
}

@internal
extension PkgPropertyMapX on Map<String, PkgProperty> {
  String encode() => entries
      .map(
        (e) =>
            e.value.isEmpty
                ? null
                : '${e.key}=${e.value.encode(width: e.key.length + 1)}',
      )
      .whereType<String>()
      .join('\n');
}

@internal
@freezed
class PkgFunction with _$PkgFunction {
  const factory PkgFunction(List<String> commands) = _PkgFunction;
  const PkgFunction._();

  String encode(String name) => '''
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
