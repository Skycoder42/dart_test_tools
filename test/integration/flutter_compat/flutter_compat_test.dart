@TestOn('dart-vm')
library;

import 'dart:io';

import 'package:dart_test_tools/src/flutter_compat/flutter_compat.dart';
import 'package:path/path.dart';
import 'package:test/test.dart';

void main() {
  group('$FlutterCompat', () {
    late Directory testDir;

    Future<void> writeFile(String path, String content) async {
      final file = File(join(testDir.path, path));
      await file.parent.create(recursive: true);
      await file.writeAsString(content);
    }

    Future<void> writePackage({
      String path = '.',
      String name = 'test_package',
      String sdk = '^3.9.0',
      String extra = '',
    }) => writeFile(join(path, 'pubspec.yaml'), '''
name: $name
version: 1.0.0
environment:
  sdk: $sdk
$extra''');

    Future<FlutterCompatResult> check([String path = '.']) =>
        FlutterCompat(directory: Directory(join(testDir.path, path)))();

    setUp(() async {
      testDir = await Directory.systemTemp.createTemp();
    });

    tearDown(() => testDir.delete(recursive: true));

    group('plain package', () {
      test('compatible package is compatible', () async {
        await writePackage(
          extra: '''
dependencies:
  path: ^1.9.0
dev_dependencies:
  meta: ">=1.15.0 <1.17.0"
''',
        );

        expect(await check(), FlutterCompatResult.compatible);
      });

      test('meta floor is incompatible', () async {
        await writePackage(
          extra: '''
dependencies:
  meta: ">=1.15.0 <1.17.0"
''',
        );

        expect(await check(), FlutterCompatResult.incompatible);
      });

      test('exact pin is incompatible', () async {
        await writePackage(
          extra: '''
dependencies:
  material_color_utilities: 0.11.1
''',
        );

        expect(await check(), FlutterCompatResult.incompatible);
      });

      test('intl is incompatible with flutter_localizations', () async {
        await writePackage(
          extra: '''
dependencies:
  intl: ^0.19.0
''',
        );

        expect(await check(), FlutterCompatResult.incompatible);
      });

      test('too new dart sdk is incompatible', () async {
        await writePackage(sdk: '^3.99.0');

        expect(await check(), FlutterCompatResult.incompatible);
      });

      test('too new flutter sdk is incompatible', () async {
        await writePackage(
          extra: '''
  flutter: ">=99.0.0"
''',
        );

        expect(await check(), FlutterCompatResult.incompatible);
      });
    });

    group('workspace', () {
      Future<void> writeWorkspace(List<String> members) =>
          writeFile('pubspec.yaml', '''
name: workspace
publish_to: none
environment:
  sdk: ^3.9.0
workspace:
${members.map((member) => '  - packages/$member').join('\n')}
''');

      Future<void> writeMember(String name, {String extra = ''}) =>
          writePackage(
            path: join('packages', name),
            name: name,
            extra: 'resolution: workspace\n$extra',
          );

      test('member with hosted sibling dependency is compatible', () async {
        await writeWorkspace(['wsa', 'wsb']);
        await writeMember(
          'wsa',
          extra: '''
dependencies:
  wsb: ^1.0.0
''',
        );
        await writeMember('wsb');

        expect(await check(), FlutterCompatResult.compatible);
      });

      test('one incompatible member is incompatible', () async {
        await writeWorkspace(['wsa', 'wsb']);
        await writeMember('wsa');
        await writeMember(
          'wsb',
          extra: '''
dependencies:
  meta: ">=1.15.0 <1.17.0"
''',
        );

        expect(await check(), FlutterCompatResult.incompatible);
      });

      test('flutter and unpublished members are skipped', () async {
        await writeWorkspace(['wsa', 'wsflutter', 'wsprivate']);
        await writeMember('wsa');
        await writeMember(
          'wsflutter',
          extra: '''
dependencies:
  flutter:
    sdk: flutter
  meta: ">=1.15.0 <1.17.0"
''',
        );
        await writeMember(
          'wsprivate',
          extra: '''
publish_to: none
dependencies:
  meta: ">=1.15.0 <1.17.0"
''',
        );

        expect(await check(), FlutterCompatResult.compatible);
      });

      test('only skipped members leave nothing to check', () async {
        await writeWorkspace(['wsprivate']);
        await writeMember('wsprivate', extra: 'publish_to: none\n');

        expect(await check(), FlutterCompatResult.nothingToCheck);
      });

      test('a member directory checks the whole workspace', () async {
        await writeWorkspace(['wsa', 'wsb']);
        await writeMember('wsa');
        await writeMember(
          'wsb',
          extra: '''
dependencies:
  meta: ">=1.15.0 <1.17.0"
''',
        );

        expect(
          await check(join('packages', 'wsa')),
          FlutterCompatResult.incompatible,
        );
      });
    });

    test('throws without pubspec.yaml', () async {
      await expectLater(check(), throwsA(isA<FlutterCompatException>()));
    });

    test('throws if flutter is not installed', () async {
      await writePackage();

      await expectLater(
        FlutterCompat(
          directory: testDir,
          flutterExecutable: 'flutter-does-not-exist',
        )(),
        throwsA(
          isA<FlutterCompatException>().having(
            (e) => e.message,
            'message',
            contains('--no-flutter-compat'),
          ),
        ),
      );
    });

    test('dart_test_tools itself is compatible', () async {
      expect(
        await FlutterCompat(directory: Directory.current)(),
        FlutterCompatResult.compatible,
      );
    });
  }, timeout: const Timeout(Duration(minutes: 5)));
}
