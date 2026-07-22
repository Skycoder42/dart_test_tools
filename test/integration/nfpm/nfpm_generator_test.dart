@TestOn('dart-vm')
library;

import 'dart:io';

import 'package:dart_test_tools/nfpm.dart';
import 'package:path/path.dart' as p;
import 'package:test/test.dart';
import 'package:yaml/yaml.dart';
import 'package:yaml_writer/yaml_writer.dart';

void main() {
  late Directory testDir;
  late Directory srcDir;
  late Directory outDir;
  late Directory bundleDir;

  late NfpmGenerator sut;

  setUp(() async {
    testDir = await Directory.systemTemp.createTemp();
    srcDir = await Directory.fromUri(testDir.uri.resolve('src')).create();
    outDir = await Directory.fromUri(testDir.uri.resolve('out')).create();
    bundleDir = await Directory.fromUri(testDir.uri.resolve('bundle')).create();

    sut = const NfpmGenerator();
  });

  tearDown(() async {
    await testDir.delete(recursive: true);
  });

  Future<void> writePubspec(Map<String, dynamic> overrides) async {
    final pubspec = <String, dynamic>{
      'name': 'test_package',
      'description': 'A pubspec description.',
      'version': '1.0.0-beta.1+3',
      'homepage': 'https://example.com/home',
      'repository': 'https://example.com/repo',
      'environment': {'sdk': '^3.12.0'},
      'executables': {'srv': null, 'my-cli': 'cli_main'},
      ...overrides,
    };
    await File.fromUri(
      srcDir.uri.resolve('pubspec.yaml'),
    ).writeAsString(YamlWriter().write(pubspec));
  }

  // Omits name/description/homepage so the tool fills them from the pubspec; a
  // template opts out of that by providing a concrete value or a ${...} token.
  Future<void> writeTemplate([String? extra]) async {
    await File.fromUri(srcDir.uri.resolve('nfpm.yaml')).writeAsString('''
version: \${PUB_VERSION}
maintainer: Test Maintainer <test@example.com>
arch: \${BUNDLE_ARCH}
contents:
  - src: \${PUB_ROOT}/tool/config.yaml
    dst: /etc/config.yaml
    type: config
${extra ?? ''}''');
  }

  Future<void> writeChangelog() async {
    await File.fromUri(srcDir.uri.resolve('CHANGELOG.md')).writeAsString('''
# Changelog
All notable changes to this project will be documented in this file.

## [1.0.0] - 2024-01-15
### Added
- The first feature

## [0.9.0] - 2024-01-01
### Fixed
- An important bug

[1.0.0]: https://example.com/compare/v0.9.0...v1.0.0
[0.9.0]: https://example.com/releases/tag/v0.9.0
''');
  }

  Future<YamlMap> generateAndLoad() async {
    await sut.generate(
      inputDirectory: srcDir,
      templateFile: File.fromUri(srcDir.uri.resolve('nfpm.yaml')),
      outputDirectory: outDir,
      bundleRoot: bundleDir,
    );
    final content = await File.fromUri(
      outDir.uri.resolve('nfpm.yaml'),
    ).readAsString();
    return loadYaml(content) as YamlMap;
  }

  List<YamlMap> contentsOfType(YamlMap nfpm, String type) =>
      (nfpm['contents'] as YamlList)
          .cast<YamlMap>()
          .where((e) => e['type'] == type)
          .toList();

  List<YamlMap> licenseEntries(YamlMap nfpm) => (nfpm['contents'] as YamlList)
      .cast<YamlMap>()
      .where(
        (e) =>
            (e['dst'] as String?)?.startsWith('/usr/share/licenses/') ?? false,
      )
      .toList();

  test('fills metadata from pubspec when template values are unset', () async {
    await writePubspec({});
    await writeTemplate();

    final nfpm = await generateAndLoad();

    expect(nfpm['name'], 'test_package');
    expect(nfpm['description'], 'A pubspec description.');
    expect(nfpm['homepage'], 'https://example.com/home');
  });

  test('prefers concrete template metadata over the pubspec', () async {
    await writePubspec({});
    await File.fromUri(srcDir.uri.resolve('nfpm.yaml')).writeAsString(r'''
name: template_name
description: A template description.
homepage: https://template.example.com
version: ${PUB_VERSION}
maintainer: Test <test@example.com>
contents: []
''');

    final nfpm = await generateAndLoad();

    expect(nfpm['name'], 'template_name');
    expect(nfpm['description'], 'A template description.');
    expect(nfpm['homepage'], 'https://template.example.com');
  });

  test(r'keeps a ${...} metadata placeholder for the pipeline', () async {
    await writePubspec({});
    await File.fromUri(srcDir.uri.resolve('nfpm.yaml')).writeAsString(r'''
name: ${PUB_NAME}
version: ${PUB_VERSION}
maintainer: Test <test@example.com>
contents: []
''');

    final nfpm = await generateAndLoad();

    expect(nfpm['name'], r'${PUB_NAME}');
  });

  test('falls back to repository when homepage is missing', () async {
    await writePubspec({'homepage': null});
    await writeTemplate();

    final nfpm = await generateAndLoad();

    expect(nfpm['homepage'], 'https://example.com/repo');
  });

  test('splits version into version, prerelease and release', () async {
    await writePubspec({});
    await writeTemplate();

    final nfpm = await generateAndLoad();

    expect(nfpm['version'], '1.0.0');
    expect(nfpm['prerelease'], 'beta.1');
    expect(nfpm['release'], '3');
  });

  test('omits prerelease and release for a plain version', () async {
    await writePubspec({'version': '2.4.6'});
    await writeTemplate();

    final nfpm = await generateAndLoad();

    expect(nfpm['version'], '2.4.6');
    expect(nfpm.containsKey('prerelease'), isFalse);
    expect(nfpm.containsKey('release'), isFalse);
  });

  test('fails on an unrepresentable build identifier', () async {
    await writePubspec({'version': '1.0.0+exp-sha'});
    await writeTemplate();

    await expectLater(
      () => sut.generate(
        inputDirectory: srcDir,
        templateFile: File.fromUri(srcDir.uri.resolve('nfpm.yaml')),
        outputDirectory: outDir,
        bundleRoot: bundleDir,
      ),
      throwsA(isA<FormatException>()),
    );
  });

  test('inserts generated entries ahead of existing contents', () async {
    await writePubspec({});
    await writeTemplate();
    await File.fromUri(
      srcDir.uri.resolve('LICENSE'),
    ).writeAsString('THE LICENSE');

    final nfpm = await generateAndLoad();
    final contents = (nfpm['contents'] as YamlList).cast<YamlMap>();

    // Order: bundle tree, symlinks (one per executable), license, then the
    // pre-existing template entries (the config file).
    expect(contents[0]['type'], 'tree');
    expect(contents[1]['type'], 'symlink');
    expect(contents[2]['type'], 'symlink');
    expect(contents[3]['dst'], startsWith('/usr/share/licenses/'));
    expect(contents[4]['type'], 'config');
  });

  test('adds a bundle tree entry with an absolute src', () async {
    await writePubspec({});
    await writeTemplate();

    final nfpm = await generateAndLoad();
    final trees = contentsOfType(nfpm, 'tree');

    expect(trees, hasLength(1));
    expect(trees.single['src'], bundleDir.absolute.path);
    expect(trees.single['dst'], '/opt/test_package');
  });

  test('adds a symlink for every executable with correct mapping', () async {
    await writePubspec({});
    await writeTemplate();

    final nfpm = await generateAndLoad();
    final symlinks = contentsOfType(nfpm, 'symlink');

    expect(symlinks, hasLength(2));
    expect(
      symlinks,
      contains(
        allOf(
          containsPair('src', '/opt/test_package/bin/srv'),
          containsPair('dst', '/usr/bin/srv'),
        ),
      ),
    );
    expect(
      symlinks,
      contains(
        allOf(
          containsPair('src', '/opt/test_package/bin/cli_main'),
          containsPair('dst', '/usr/bin/my-cli'),
        ),
      ),
    );
  });

  test('adds a plain-file license entry when a license file exists', () async {
    await writePubspec({});
    await writeTemplate();
    await File.fromUri(
      srcDir.uri.resolve('LICENSE'),
    ).writeAsString('THE LICENSE');

    final nfpm = await generateAndLoad();
    final licenses = licenseEntries(nfpm);

    expect(licenses, hasLength(1));
    expect(
      licenses.single['src'],
      File.fromUri(srcDir.uri.resolve('LICENSE')).resolveSymbolicLinksSync(),
    );
    // A regular file, so nfpm packages it for deb/rpm/apk alike.
    expect(licenses.single.containsKey('type'), isFalse);
  });

  test('skips the license entry when no license file exists', () async {
    await writePubspec({});
    await writeTemplate();

    final nfpm = await generateAndLoad();

    expect(licenseEntries(nfpm), isEmpty);
  });

  test('keeps untouched placeholders for the pipeline', () async {
    await writePubspec({});
    await writeTemplate();

    final nfpm = await generateAndLoad();
    final configs = contentsOfType(nfpm, 'config');

    expect(nfpm['arch'], r'${BUNDLE_ARCH}');
    expect(configs.single['src'], r'${PUB_ROOT}/tool/config.yaml');
  });

  test('generates a chglog changelog newest first', () async {
    await writePubspec({});
    await writeTemplate();
    await writeChangelog();

    final nfpm = await generateAndLoad();

    expect(
      nfpm['changelog'],
      File.fromUri(outDir.uri.resolve('changelog.yaml')).absolute.path,
    );

    final changelogContent = await File.fromUri(
      outDir.uri.resolve('changelog.yaml'),
    ).readAsString();
    final changelog = loadYaml(changelogContent) as YamlList;
    final first = changelog.first as YamlMap;
    final last = changelog.last as YamlMap;

    expect(changelog, hasLength(2));
    expect(first['semver'], '1.0.0');
    expect(first['date'], '2024-01-15T00:00:00Z');
    expect(first['packager'], 'Test Maintainer <test@example.com>');
    expect(
      (first['changes'] as YamlList).cast<YamlMap>().first['note'],
      'Added: The first feature',
    );
    expect(last['semver'], '0.9.0');
  });

  test('defaults platform and arch from the host when unset', () async {
    await writePubspec({});
    await File.fromUri(srcDir.uri.resolve('nfpm.yaml')).writeAsString(r'''
version: ${PUB_VERSION}
maintainer: Test <test@example.com>
contents: []
''');

    final nfpm = await generateAndLoad();

    expect(nfpm['platform'], anyOf('linux', 'darwin', 'windows'));
    expect(nfpm['arch'], isA<String>());
    expect((nfpm['arch'] as String).contains(r'$'), isFalse);
  });

  test('resolves a relative content src to an absolute path', () async {
    await writePubspec({});
    await writeTemplate('''
  - src: assets/app.conf
    dst: /etc/app.conf
    type: config
''');

    final nfpm = await generateAndLoad();
    final entry = (nfpm['contents'] as YamlList).cast<YamlMap>().firstWhere(
      (e) => e['dst'] == '/etc/app.conf',
    );

    expect(entry['src'], startsWith(srcDir.path));
    expect(entry['src'], endsWith(p.join('assets', 'app.conf')));
  });

  test('leaves an absolute content src untouched', () async {
    await writePubspec({});
    await writeTemplate('''
  - src: /opt/extra/file.conf
    dst: /etc/file.conf
    type: config
''');

    final nfpm = await generateAndLoad();
    final entry = (nfpm['contents'] as YamlList).cast<YamlMap>().firstWhere(
      (e) => e['dst'] == '/etc/file.conf',
    );

    expect(entry['src'], '/opt/extra/file.conf');
  });

  test('expands %{name} and %{version} in a content dst', () async {
    await writePubspec({});
    await writeTemplate('''
  - src: /opt/x
    dst: /opt/%{name}/%{version}/x
    type: file
''');

    final nfpm = await generateAndLoad();
    final entry = (nfpm['contents'] as YamlList).cast<YamlMap>().firstWhere(
      (e) => (e['dst'] as String).startsWith('/opt/test_package/'),
    );

    expect(entry['dst'], '/opt/test_package/1.0.0-beta.1+3/x');
  });

  test('treats an empty executable value like a null one', () async {
    await File.fromUri(srcDir.uri.resolve('pubspec.yaml')).writeAsString('''
name: test_package
version: 1.0.0
environment:
  sdk: ^3.12.0
executables:
  srv: ''
  tool: tool_main
''');
    await writeTemplate();

    final nfpm = await generateAndLoad();
    final symlinks = contentsOfType(nfpm, 'symlink');

    expect(
      symlinks,
      contains(
        allOf(
          containsPair('src', '/opt/test_package/bin/srv'),
          containsPair('dst', '/usr/bin/srv'),
        ),
      ),
    );
  });

  test('fails when the bundle root does not exist', () async {
    await writePubspec({});
    await writeTemplate();

    await expectLater(
      () => sut.generate(
        inputDirectory: srcDir,
        templateFile: File.fromUri(srcDir.uri.resolve('nfpm.yaml')),
        outputDirectory: outDir,
        bundleRoot: Directory.fromUri(testDir.uri.resolve('missing')),
      ),
      throwsA(isA<Exception>()),
    );
  });

  test('requires a maintainer when a changelog is present', () async {
    await writePubspec({});
    await File.fromUri(srcDir.uri.resolve('nfpm.yaml')).writeAsString(r'''
version: ${PUB_VERSION}
contents: []
''');
    await writeChangelog();

    await expectLater(
      () => sut.generate(
        inputDirectory: srcDir,
        templateFile: File.fromUri(srcDir.uri.resolve('nfpm.yaml')),
        outputDirectory: outDir,
        bundleRoot: bundleDir,
      ),
      throwsA(isA<Exception>()),
    );
  });
}
