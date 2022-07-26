import 'package:freezed_annotation/freezed_annotation.dart';

part 'pkgbuild.freezed.dart';

@internal
@freezed
class Pkgbuild with _$Pkgbuild {
  const Pkgbuild._();

  const factory Pkgbuild({
    required String maintainer,
    required Map<String, PkgProperty> properties,
    required Map<String, PkgFunction> functions,
  }) = _Pkgbuild;

  String encode() {
    return '''
# Maintainer: $maintainer
${properties.encode()}

${functions.encode()}
''';
  }
}

@internal
@freezed
class PkgProperty with _$PkgProperty {
  const PkgProperty._();

  const factory PkgProperty(Object? value) = _Single;
  const factory PkgProperty.interpolate(String value) = _Interpolate;
  const factory PkgProperty.list(List<PkgProperty> values) = _List;
  factory PkgProperty.literalList(List<String> values) =>
      PkgProperty.list(values.map(PkgProperty.new).toList());

  bool get isNull => maybeWhen(
        (value) => value == null,
        orElse: () => false,
      );

  String encode() => when(
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
        list: (values) => '(${values.map((v) => v.encode()).join(' ')})',
      );
}

@internal
extension PkgPropertyMapX on Map<String, PkgProperty> {
  String encode() => entries.map((entry) {
        if (entry.value.isNull) {
          return '# ${entry.key}=';
        } else {
          return '${entry.key}=${entry.value.encode()}';
        }
      }).join('\n');
}

@internal
@freezed
class PkgFunction with _$PkgFunction {
  const PkgFunction._();

  const factory PkgFunction(
    List<String> commands, {
    @Default(true) bool autoCd,
  }) = _PkgFunction;

  String encode(String name) {
    final actualCommands = [
      if (autoCd) 'cd "\$_pkgdir"',
      ...commands,
    ];

    return '''
$name() {
${actualCommands.map((c) => '  $c').join('\n')}
}
''';
  }
}

@internal
extension PkgFunctionMapX on Map<String, PkgFunction> {
  String encode() =>
      entries.map((entry) => entry.value.encode(entry.key)).join('\n');
}
