@TestOn('dart-vm')
library;

import 'dart:io';

import 'package:analyzer/dart/analysis/analysis_context_collection.dart';
import 'package:analyzer/dart/analysis/results.dart';
import 'package:analyzer/dart/element/element.dart';
import 'package:code_builder/code_builder.dart';
import 'package:dart_test_tools/code_gen.dart';
import 'package:dart_test_tools/test.dart';
import 'package:path/path.dart' as p;
import 'package:source_gen/source_gen.dart';
import 'package:test/test.dart';

const _source = '''
class Annotation {
  const Annotation(this.value);

  final Object? value;
}

class Wrapper {
  const Wrapper(this.name, {this.deps = const []});

  final String name;
  final List<Object> deps;
}

class Holder {
  const Holder();

  static int staticMethod() => 0;
}

int topLevelFunction(int value) => value;

@Annotation(null)
const nullValue = 0;

@Annotation('a string')
const stringValue = 0;

@Annotation(42)
const intValue = 0;

@Annotation(#a.symbol)
const symbolValue = 0;

@Annotation(Holder)
const typeValue = 0;

@Annotation(Holder())
const revivedValue = 0;

@Annotation(<int>[])
const emptyList = 0;

@Annotation([1, 'two', null, true])
const literalList = 0;

@Annotation([topLevelFunction, Holder.staticMethod])
const functionList = 0;

@Annotation([Holder, int, List<String>])
const typeList = 0;

@Annotation([[1, 2], []])
const nestedList = 0;

@Annotation([Holder()])
const revivedList = 0;

@Annotation(<Object>{topLevelFunction, 'x'})
const setValue = 0;

@Annotation(<String, Object>{'fn': topLevelFunction, 'nested': [1]})
const mapValue = 0;

@Annotation(Wrapper('name', deps: [topLevelFunction]))
const revivedWithCollection = 0;
''';

void main() {
  late Directory testDir;
  late LibraryElement library;

  setUpAll(() async {
    testDir = await Directory.systemTemp.createTemp();
    final sourceFile = File.fromUri(testDir.uri.resolve('annotations.dart'));
    await sourceFile.writeAsString(_source);

    final collection = AnalysisContextCollection(
      includedPaths: [p.normalize(sourceFile.absolute.path)],
    );
    final context = collection.contextFor(
      p.normalize(sourceFile.absolute.path),
    );
    final result = await context.currentSession.getResolvedLibrary(
      p.normalize(sourceFile.absolute.path),
    );
    library = (result as ResolvedLibraryResult).element;
  });

  tearDownAll(() async {
    await testDir.delete(recursive: true);
  });

  // Emits the annotations "value" as dart code, without the trailing commas
  // that the emitter adds after collection elements and arguments.
  String annotationValueOf(String variableName) {
    final variable = library.topLevelVariables.singleWhere(
      (v) => v.name == variableName,
    );
    final annotation = variable.metadata.annotations.single;
    final reader = ConstantReader(annotation.computeConstantValue())
        .read('value');
    return reader
        .toExpression()
        .accept(DartEmitter())
        .toString()
        .replaceAll(RegExp(r',\s*(?=[)\]}])'), '');
  }

  group('toExpression', () {
    testData<(String, String)>(
      'converts simple constants',
      const [
        ('nullValue', 'null'),
        ('stringValue', "'a string'"),
        ('intValue', '42'),
        ('symbolValue', '#a.symbol'),
        ('typeValue', 'Holder'),
        ('revivedValue', 'Holder()'),
      ],
      (fixture) {
        final (variableName, expected) = fixture;
        expect(annotationValueOf(variableName), expected);
      },
    );

    testData<(String, String)>(
      'converts collection constants',
      const [
        ('emptyList', '[]'),
        ('literalList', "[1, 'two', null, true]"),
        ('functionList', '[topLevelFunction, Holder.staticMethod]'),
        ('typeList', '[Holder, int, List<String>]'),
        ('nestedList', '[[1, 2], []]'),
        ('revivedList', '[Holder()]'),
        ('setValue', "{topLevelFunction, 'x'}"),
        ('mapValue', "{'fn': topLevelFunction, 'nested': [1]}"),
        ('revivedWithCollection', "Wrapper('name', deps: [topLevelFunction])"),
      ],
      (fixture) {
        final (variableName, expected) = fixture;
        expect(annotationValueOf(variableName), expected);
      },
    );
  });
}
