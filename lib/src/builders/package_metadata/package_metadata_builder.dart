import 'dart:async';

import 'package:build/build.dart';
import 'package:code_builder/code_builder.dart';
import 'package:pubspec_parse/pubspec_parse.dart';

import '../../code_gen/references.dart';

class PackageMetadataBuilder extends Builder {
  final BuilderOptions options;

  PackageMetadataBuilder(this.options);

  @override
  Map<String, List<String>> get buildExtensions => const {
    'pubspec.yaml': ['lib/gen/package_metadata.dart'],
  };

  bool get strictTypes => options.config['strictTypes'] as bool? ?? false;

  @override
  Future<void> build(BuildStep buildStep) async {
    final outAsset = buildStep.allowedOutputs.single;

    final pubspecYaml = await buildStep.readAsString(buildStep.inputId);
    final pubspec = Pubspec.parse(
      pubspecYaml,
      sourceUrl: buildStep.inputId.uri,
    );

    final library = _buildLibrary(pubspec);

    final emitter = DartEmitter.scoped(
      orderDirectives: true,
      useNullSafetySyntax: true,
    );
    final buffer = StringBuffer();
    library.accept(emitter, buffer);
    await buildStep.writeAsString(outAsset, buffer.toString());
  }

  Library _buildLibrary(Pubspec pubspec) => Library(
    (b) => b
      ..ignoreForFile.add('type=lint')
      ..body.addAll([
        _buildReqStringField('package', pubspec.name),
        _buildStringField('version', pubspec.version?.canonicalizedVersion),
        _buildStringField('description', pubspec.description),
        _buildStrUriField('homepage', pubspec.homepage),
        _buildUriField('repository', pubspec.repository),
        _buildUriField('issueTracker', pubspec.issueTracker),
        _buildUriListField('funding', pubspec.funding),
        _buildStringListField('topics', pubspec.topics),
        _buildStrUriField('documentation', pubspec.documentation),
      ]),
  );

  Field _buildReqStringField(String name, String value) =>
      _buildField(name, CoreTypes.$String, literalString(value, raw: true));

  Field _buildStringField(String name, String? value) => _buildField(
    name,
    CoreTypes.$String.asNullable(true),
    value != null ? literalString(value, raw: true) : literalNull,
  );

  Field _buildStringListField(String name, Iterable<String>? values) =>
      _buildField(
        name,
        CoreTypes.$List(CoreTypes.$String),
        values != null
            ? literalList(values)
            : literalList(const [], CoreTypes.$String),
      );

  Field _buildUriField(String name, Uri? value) => _buildField(
    modifier: .final$,
    name,
    CoreTypes.$Uri.asNullable(true),
    value != null
        ? CoreTypes.$Uri.newInstanceNamed('parse', [
            literalString(value.toString(), raw: true),
          ])
        : literalNull,
  );

  Field _buildStrUriField(String name, String? value) =>
      _buildUriField(name, value != null ? Uri.parse(value) : null);

  Field _buildUriListField(String name, Iterable<Uri>? values) => _buildField(
    modifier: values != null ? .final$ : .constant,
    name,
    CoreTypes.$List(CoreTypes.$Uri),
    values != null
        ? literalList([
            for (final value in values)
              CoreTypes.$Uri.newInstanceNamed('parse', [
                literalString(value.toString(), raw: true),
              ]),
          ])
        : literalList(const [], CoreTypes.$Uri),
  );

  Field _buildField(
    String name,
    Reference type,
    Expression value, {
    FieldModifier modifier = .constant,
  }) => Field(
    (b) => b
      ..name = name
      ..modifier = modifier
      ..type = strictTypes || value == literalNull ? type : null
      ..assignment = value.code,
  );
}
