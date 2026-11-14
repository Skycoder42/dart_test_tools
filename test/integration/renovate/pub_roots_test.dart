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

    test('plain package at root', () async {
      await writePubspec('.', 'name: root\n');

      final result = await sut.findRoot('pubspec.yaml');

      expect(result, '.');
    });

    test('package in sub/dir', () async {
      await writePubspec('sub/dir', 'name: sub\n');

      final result = await sut.findRoot('sub/dir/pubspec.yaml');

      expect(result, 'sub/dir');
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

      expect(await sut.findRoot('packages/a/pubspec.yaml'), PubRoots.root);
      expect(await sut.findRoot('packages/b/pubspec.yaml'), PubRoots.root);
      expect(await sut.findRoot('pubspec.yaml'), PubRoots.root);
    });

    test('package next to a workspace is its own root', () async {
      await writePubspec('.', '''
name: workspace
workspace:
  - packages/a
''');
      await writePubspec('packages/a', 'name: a\nresolution: workspace\n');
      await writePubspec('tool/sub', 'name: sub\n');

      expect(await sut.findRoot('tool/sub/pubspec.yaml'), 'tool/sub');
      expect(await sut.findRoot('packages/a/pubspec.yaml'), PubRoots.root);
    });

    test('member without workspace at repo root', () async {
      await writePubspec('.', 'name: root\n');
      await writePubspec('packages/a', 'name: a\nresolution: workspace\n');

      expect(
        () => sut.findRoot('packages/a/pubspec.yaml'),
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
        () => sut.findRoot('ws/packages/a/pubspec.yaml'),
        throwsA(isA<StateError>()),
      );
    });

    test('member not listed in root workspace', () async {
      await writePubspec('.', 'name: root\nworkspace:\n  - packages/b\n');
      await writePubspec('packages/a', 'name: a\nresolution: workspace\n');
      await writePubspec('packages/b', 'name: b\nresolution: workspace\n');

      expect(
        () => sut.findRoot('packages/a/pubspec.yaml'),
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

      final result = await sut.findRoot('packages/a/pubspec.yaml');

      expect(result, '.');
    });

    test('member listed with a non-normalized path', () async {
      await writePubspec('.', 'name: root\nworkspace:\n  - ./packages/a/\n');
      await writePubspec('packages/a', 'name: a\nresolution: workspace\n');

      final result = await sut.findRoot('packages/a/pubspec.yaml');

      expect(result, '.');
    });
  });
}
