import 'dart:async';

import 'package:build/build.dart';
import 'package:code_builder/code_builder.dart';
import 'package:pubspec_parse/pubspec_parse.dart';

class PackageMetadataBuilder extends Builder {
  static final _string = TypeReference((b) => b..symbol = 'String');
  static final _uri = TypeReference((b) => b..symbol = 'Uri');

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
      _buildField(name, _string, literalString(value, raw: true));

  Field _buildStringField(String name, String? value) => _buildField(
    name,
    _string.nullable,
    value != null ? literalString(value, raw: true) : literalNull,
  );

  Field _buildStringListField(String name, Iterable<String>? values) =>
      _buildField(
        name,
        _string.list,
        values != null ? literalList(values) : literalList(const [], _string),
      );

  Field _buildUriField(String name, Uri? value) => _buildField(
    modifier: FieldModifier.final$,
    name,
    _uri.nullable,
    value != null
        ? _uri.newInstanceNamed('parse', [
            literalString(value.toString(), raw: true),
          ])
        : literalNull,
  );

  Field _buildStrUriField(String name, String? value) =>
      _buildUriField(name, value != null ? Uri.parse(value) : null);

  Field _buildUriListField(String name, Iterable<Uri>? values) => _buildField(
    modifier: values != null ? FieldModifier.final$ : FieldModifier.constant,
    name,
    _uri.list,
    values != null
        ? literalList([
            for (final value in values)
              _uri.newInstanceNamed('parse', [
                literalString(value.toString(), raw: true),
              ]),
          ])
        : literalList(const [], _uri),
  );

  Field _buildField(
    String name,
    Reference type,
    Expression value, {
    FieldModifier modifier = FieldModifier.constant,
  }) => Field(
    (b) => b
      ..name = name
      ..modifier = modifier
      ..type = strictTypes || value == literalNull ? type : null
      ..assignment = value.code,
  );
}

extension on TypeReference {
  TypeReference get nullable => TypeReference(
    (b) => b
      ..replace(this)
      ..isNullable = true,
  );

  TypeReference get list => TypeReference(
    (b) => b
      ..symbol = 'List'
      ..types.add(this),
  );
}
