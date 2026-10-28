@TestOn('dart-vm')
library;

import 'dart:io';

import 'package:dart_test_tools/src/renovate/pub_roots.dart';
import 'package:path/path.dart';
import 'package:test/test.dart';

void main() {
  group('$PubRoots', () {
    late Directory testDir;
    late PubRoots sut;

    setUp(() async {
      testDir = await Directory.systemTemp.createTemp();
      sut = PubRoots(testDir);
    });

    tearDown(() async {
      await testDir.delete(recursive: true);
    });

    Future<void> writePubspec(String path, String content) async {
      final file = File(join(testDir.path, path, 'pubspec.yaml'));
      await file.parent.create(recursive: true);
      await file.writeAsString(content);
    }

    Matcher isDir(String path) => isA<Directory>().having(
      (d) => d.absolute.path,
      'absolute path',
      normalize(join(testDir.absolute.path, path)),
    );

    test('plain package at root', () async {
      await writePubspec('.', 'name: root\n');

      final result = await sut.resolve(['pubspec.yaml']);

      expect(result, [isDir('.')]);
    });

    test('package in sub/dir', () async {
      await writePubspec('sub/dir', 'name: sub\n');

      final result = await sut.resolve(['sub/dir/pubspec.yaml']);

      expect(result, [isDir('sub/dir')]);
    });

    test('two members of one workspace', () async {
      await writePubspec('.', '''
name: workspace
workspace:
  - packages/a
  - packages/b
''');
      await writePubspec('packages/a', 'name: a\nresolution: workspace\n');
      await writePubspec('packages/b', 'name: b\nresolution: workspace\n');

      final result = await sut.resolve([
        'packages/a/pubspec.yaml',
        'packages/b/pubspec.yaml',
        'pubspec.yaml',
      ]);

      expect(result, [isDir('.')]);
    });

    test('keeps first-seen order of distinct roots', () async {
      await writePubspec('.', '''
name: workspace
workspace:
  - packages/a
''');
      await writePubspec('packages/a', 'name: a\nresolution: workspace\n');
      await writePubspec('tool/sub', 'name: sub\n');

      final result = await sut.resolve([
        'tool/sub/pubspec.yaml',
        'packages/a/pubspec.yaml',
        'pubspec.yaml',
      ]);

      expect(result, [isDir('tool/sub'), isDir('.')]);
    });

    test('member without workspace at repo root', () async {
      await writePubspec('.', 'name: root\n');
      await writePubspec('packages/a', 'name: a\nresolution: workspace\n');

      expect(
        () => sut.resolve(['packages/a/pubspec.yaml']),
        throwsA(
          isA<StateError>().having(
            (e) => e.message,
            'message',
            contains('packages/a'),
          ),
        ),
      );
    });

    test('member in nested workspace', () async {
      await writePubspec('.', 'name: root\n');
      await writePubspec('ws', 'name: ws\nworkspace:\n  - packages/a\n');
      await writePubspec('ws/packages/a', 'name: a\nresolution: workspace\n');

      expect(
        () => sut.resolve(['ws/packages/a/pubspec.yaml']),
        throwsA(isA<StateError>()),
      );
    });

    test('member not listed in root workspace', () async {
      await writePubspec('.', 'name: root\nworkspace:\n  - packages/b\n');
      await writePubspec('packages/a', 'name: a\nresolution: workspace\n');
      await writePubspec('packages/b', 'name: b\nresolution: workspace\n');

      expect(
        () => sut.resolve(['packages/a/pubspec.yaml']),
        throwsA(
          isA<StateError>().having(
            (e) => e.message,
            'message',
            contains('packages/a'),
          ),
        ),
      );
    });

    test('member matched by a glob entry', () async {
      await writePubspec('.', 'name: root\nworkspace:\n  - packages/*\n');
      await writePubspec('packages/a', 'name: a\nresolution: workspace\n');

      final result = await sut.resolve(['packages/a/pubspec.yaml']);

      expect(result, [isDir('.')]);
    });

    test('member listed with a non-normalized path', () async {
      await writePubspec('.', 'name: root\nworkspace:\n  - ./packages/a/\n');
      await writePubspec('packages/a', 'name: a\nresolution: workspace\n');

      final result = await sut.resolve(['packages/a/pubspec.yaml']);

      expect(result, [isDir('.')]);
    });
  });
}
