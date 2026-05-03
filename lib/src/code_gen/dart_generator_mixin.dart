import 'package:build/build.dart';
import 'package:code_builder/code_builder.dart';
import 'package:dart_style/dart_style.dart';

mixin DartGeneratorMixin {
  String createDartCode(
    Spec spec, {
    bool scoped = true,
    bool format = false,
    Uri? uri,
  }) {
    final buffer = StringBuffer();
    final emitter = scoped
        ? DartEmitter.scoped(orderDirectives: true, useNullSafetySyntax: true)
        : DartEmitter(orderDirectives: true, useNullSafetySyntax: true);

    spec.accept(emitter, buffer);

    if (format) {
      return DartFormatter(
        languageVersion: DartFormatter.latestLanguageVersion,
      ).format(buffer.toString(), uri: uri);
    } else {
      return buffer.toString();
    }
  }

  Future<void> writeDartCode(
    BuildStep buildStep,
    AssetId assetId,
    Spec spec, {
    bool scoped = true,
    bool format = true,
  }) => buildStep.writeAsString(
    assetId,
    createDartCode(spec, scoped: scoped, format: format, uri: assetId.uri),
  );
}
