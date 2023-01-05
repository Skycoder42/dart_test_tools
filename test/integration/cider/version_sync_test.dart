import 'dart:io';

import 'package:cider/cider.dart';
import 'package:dart_test_tools/src/cider_plugins/version_sync_plugin.dart';
import 'package:test/test.dart';
import 'package:yaml_writer/yaml_writer.dart';

void main() {
  late Directory testDir;
  late Cider cider;

  setUp(() async {
    testDir = await Directory.systemTemp.createTemp();

    await createTestProject(testDir);

    cider = Cider(
      root: testDir,
      plugins: [const VersionSyncPlugin()],
    );
  });

  tearDown(() async {
    await testDir.delete(recursive: true);
  });

  test('nothing', () async {
    final result = await cider.run(const ['version-sync']);
    expect(result, 0);
  });
}

Future<void> run(
  String executable,
  List<String> arguments, {
  String? workingDirectory,
}) async {
  final proc = await Process.start(
    executable,
    arguments,
    workingDirectory: workingDirectory,
    mode: ProcessStartMode.inheritStdio,
  );
  await expectLater(proc.exitCode, completion(0));
}

Future<void> createTestProject(Directory pwd, String version) async {
  await run(
    'flutter',
    const [
      'create',
      '--project-name',
      'version_sync_test',
      '--platforms',
      'android',
      '--platforms',
      'ios',
      '--platforms',
      'linux',
      '--platforms',
      'macos',
      '--platforms',
      'windows',
      '--platforms',
      'web',
      '--template',
      'plugin',
      '.'
    ],
    workingDirectory: pwd.path,
  );

  await Directory.fromUri(pwd.uri.resolve('lib/src')).create();
  await File.fromUri(pwd.uri.resolve('lib/src/version.dart'))
      .writeAsString(flush: true, '''
// this is the library version
const version = '1.5.8';
const name = 'version_sync_test';
''');

  final pubspecWriter = YAMLWriter();

  await File.fromUri(pwd.uri.resolve('pubspec.yaml')).writeAsString(
    mode: FileMode.append,
    flush: true,
    r'''
cider:
  version_sync:
    lib/src/version.dart:
      pattern: "^const version = '.*';$"
      replacement: "const version = '%{version}';"
''',
  );
}
