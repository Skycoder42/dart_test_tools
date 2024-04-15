import 'dart:io';

import 'package:dart_test_tools/src/ci/build_number_generator.dart';
import 'package:dart_test_tools/src/test/test_data.dart';
import 'package:dart_test_tools/src/tools/io.dart';
import 'package:test/test.dart';

void main() {
  group('$BuildNumberGenerator', () {
    late Directory testDir;

    const sut = BuildNumberGenerator();

    setUp(() async {
      testDir = await Directory.systemTemp.createTemp();
      Directory.current = testDir;
    });

    tearDown(() async {
      await testDir.delete(recursive: true);
    });

    testData<(String, int, int, String)>(
      'generates correct build number for version number and parameters',
      const [
        ('1.2.3', 2, 2, '10203'),
        ('1.23.4', 2, 2, '12304'),
        ('1.2.34', 2, 2, '10234'),
        ('1.23.45', 2, 2, '12345'),
        ('1.2.3', 3, 4, '10020003'),
        ('1.234.5678', 3, 4, '12345678'),
      ],
      (fixture) async {
        await testDir.subFile('pubspec.yaml').writeAsString('''
name: test_package
version: ${fixture.$1}
''');

        await sut(minorWidth: fixture.$2, patchWidth: fixture.$3);

        final output =
            await File(Platform.environment['GITHUB_OUTPUT']!).readAsLines();
        expect(output.last, 'buildNumber=${fixture.$4}');
      },
    );

    testData<String>(
      'throws if version number exceeds padding limits',
      const ['1.234.5', '1.2.345', '1.234.567'],
      (fixture) async {
        await testDir.subFile('pubspec.yaml').writeAsString('''
name: test_package
version: $fixture
''');

        expect(
          sut.call,
          throwsException,
        );
      },
    );

    test('write to env if specified', () async {
      await testDir.subFile('pubspec.yaml').writeAsString('''
name: test_package
version: 1.2.3
''');

      await sut(asEnv: true);

      final output =
          await File(Platform.environment['GITHUB_ENV']!).readAsLines();
      expect(output.last, 'BUILD_NUMBER=10203');
    });
  });
}
