import 'dart:io';

import 'package:checks/checks.dart';
import 'package:dart_test_tools/src/pub/models/pub/dependency_kind.dart';
import 'package:dart_test_tools/src/pub/models/pub/outdated/outdated_info.dart';
import 'package:dart_test_tools/src/pub/models/pub/outdated/package_info.dart';
import 'package:dart_test_tools/src/pub/models/pub/outdated/version_info.dart';
import 'package:dart_test_tools/src/pub/models/pub/workspace/workspace_info.dart';
import 'package:dart_test_tools/src/pub/models/pub/workspace/workspaces.dart';
import 'package:dart_test_tools/src/renovate/global_config.dart';
import 'package:dart_test_tools/src/renovate/renovate_preset.dart';
import 'package:dart_test_tools/src/test/test_data.dart';
import 'package:mockito/mockito.dart';
import 'package:pub_semver/pub_semver.dart';
import 'package:test/scaffolding.dart';

import '../_support/mocks.dart';

void main() {
  group('$GlobalConfig', () {
    final repository = Directory('repo');

    setUpAll(provideMockDummies);
    final mockPubFactory = MockPubWrapperFactory();
    final mockPub = MockPubWrapper();

    PackageInfo package(
      String name,
      String resolvable,
      String latest, {
      DependencyKind kind = .direct,
    }) => PackageInfo(
      package: name,
      kind: kind,
      resolvable: VersionInfo(version: Version.parse(resolvable)),
      latest: VersionInfo(version: Version.parse(latest)),
    );

    List<Map<String, dynamic>> packageRules(Map<String, dynamic> config) =>
        (config['packageRules'] as List).cast<Map<String, dynamic>>();

    GlobalConfig sut(RenovatePreset preset) => GlobalConfig(
      repository: repository,
      preset: preset,
      pubFactory: mockPubFactory,
    );

    setUp(() {
      reset(mockPubFactory);
      reset(mockPub);

      when(mockPubFactory.create(any, forceFlutter: anyNamed('forceFlutter')))
          .thenAnswer((_) async => mockPub);
      when(mockPub.workspaceList()).thenAnswer(
        (_) async => const Workspaces(
          packages: [
            WorkspaceInfo(name: 'workspace', path: '/repo'),
            WorkspaceInfo(name: 'a', path: '/repo/packages/a'),
            WorkspaceInfo(name: 'b', path: '/repo/packages/b'),
          ],
        ),
      );
      when(mockPub.outdated())
          .thenAnswer((_) async => const OutdatedInfo(packages: []));
    });

    test('contains fixed global values', () async {
      final config = await sut(.application).build();

      check(config)
        ..has('platform', (c) => c['platform']).equals('github')
        ..has('onboarding', (c) => c['onboarding']).equals(false)
        ..has('requireConfig', (c) => c['requireConfig']).equals('required')
        ..has('binarySource', (c) => c['binarySource']).equals('global')
        ..has('repositoryCache', (c) => c['repositoryCache']).equals('enabled')
        ..has('executionTimeout', (c) => c['executionTimeout']).equals(30)
        ..has(
          'allowedCommands',
          (c) => c['allowedCommands'],
        ).isA<List<String>>().deepEquals([
          r'^renovate-post-upgrade --mode (application|library)$',
        ])
        ..not(.it()..containsKey('dependencyDashboard'));
    });

    testData<RenovatePreset>(
      'resolves the repository with flutter if the preset enforces flutter '
      'compatibility',
      RenovatePreset.values,
      dataToString: (preset) => preset.name,
      (preset) async {
        await sut(preset).build();

        verify(
          mockPubFactory.create(repository, forceFlutter: preset.flutterCompat),
        ).called(1);
      },
    );

    test('workspace rule lists all workspace package names', () async {
      final config = await sut(.application).build();

      check(packageRules(config)).single.deepEquals({
        'description': 'Workspace packages are resolved locally',
        'matchManagers': ['pub'],
        'matchPackageNames': ['workspace', 'a', 'b'],
        'enabled': false,
      });
    });

    test('caps outdated packages except workspace members', () async {
      when(mockPub.outdated()).thenAnswer(
        (_) async => OutdatedInfo(
          packages: [
            package('test', '1.31.1', '1.33.0', kind: .dev),
            package('a', '1.0.0', '2.0.0'),
            package('meta', '1.17.0', '1.17.0'),
            package('collection', '1.18.0', '1.19.0', kind: .transitive),
          ],
        ),
      );

      final config = await sut(.application).build();

      check(packageRules(config)).deepEquals([
        {
          'description': 'Workspace packages are resolved locally',
          'matchManagers': ['pub'],
          'matchPackageNames': ['workspace', 'a', 'b'],
          'enabled': false,
        },
        {
          'description': 'Newest resolvable version is 1.31.1',
          'matchManagers': ['pub'],
          'matchPackageNames': ['test'],
          'allowedVersions': '<=1.31.1',
        },
      ]);
      check((config['dependencyDashboard'] as Map)['footer'])
          .isA<String>()
          .contains('| `test` | 1.31.1 | `>1.31.1` | 1.33.0 |');
    });

    test('adds flutter_test for the library preset before checking for '
        'outdated packages', () async {
      when(mockPub.dependsOnFlutterTest()).thenAnswer((_) async => false);

      await sut(.library).build();

      verifyInOrder([mockPub.addFlutterTest(), mockPub.outdated()]);
    });

    test('does not add flutter_test for the library preset if a package '
        'depends on it', () async {
      when(mockPub.dependsOnFlutterTest()).thenAnswer((_) async => true);

      await sut(.library).build();

      verifyNever(mockPub.addFlutterTest());
    });

    test('does not add flutter_test for the application preset', () async {
      await sut(.application).build();

      verifyNever(mockPub.dependsOnFlutterTest());
      verifyNever(mockPub.addFlutterTest());
    });

    group('$ResolvableCap', () {
      ResolvableCap? cap(
        String resolvable,
        String latest, {
        DependencyKind kind = .direct,
        bool offerBreaking = true,
      }) => ResolvableCap.fromPackage(
        package('pkg', resolvable, latest, kind: kind),
        offerBreaking: offerBreaking,
      );

      test('is null if resolvable is latest', () {
        check(cap('1.2.3', '1.2.3')).isNull;
      });

      testData<DependencyKind>(
        'is null for transitive and root packages',
        const [.transitive, .root],
        dataToString: (kind) => kind.name,
        (kind) => check(cap('1.2.3', '1.3.0', kind: kind)).isNull,
      );

      test('caps minor and patch updates', () {
        check(cap('13.3.0', '13.5.1')).isNotNull()
          ..has('heldBack', (c) => c.heldBack).equals('>13.3.0')
          ..has('packageRule', (c) => c.packageRule).deepEquals({
            'description': 'Newest resolvable version is 13.3.0',
            'matchManagers': ['pub'],
            'matchPackageNames': ['pkg'],
            'allowedVersions': '<=13.3.0',
          });
      });

      test('keeps major updates allowed with offerBreaking', () {
        check(cap('13.3.0', '14.7.0')).isNotNull()
          ..has('heldBack', (c) => c.heldBack).equals('>13.3.0 <14.0.0')
          ..has('packageRule', (c) => c.packageRule).deepEquals({
            'description':
                'Newest resolvable version is 13.3.0, breaking updates '
                'stay allowed',
            'matchManagers': ['pub'],
            'matchPackageNames': ['pkg'],
            'allowedVersions': '<=13.3.0 || >=14.0.0',
          });
      });

      test('caps major updates without offerBreaking', () {
        check(cap('13.3.0', '14.7.0', offerBreaking: false)).isNotNull()
          ..has('heldBack', (c) => c.heldBack).equals('>13.3.0')
          ..has('packageRule', (c) => c.packageRule).deepEquals({
            'description': 'Newest resolvable version is 13.3.0',
            'matchManagers': ['pub'],
            'matchPackageNames': ['pkg'],
            'allowedVersions': '<=13.3.0',
          });
      });

      test('treats 0.x minor updates as breaking', () {
        check(cap('0.14.12', '0.15.2')?.allowedVersions)
            .equals('<=0.14.12 || >=0.15.0');
        check(cap('0.14.12', '0.14.20')?.allowedVersions).equals('<=0.14.12');
        check(cap('0.14.12', '0.15.2', offerBreaking: false)?.allowedVersions)
            .equals('<=0.14.12');
      });
    });

    group('heldBackFooter', () {
      List<ResolvableCap> caps(RenovatePreset preset) => [
        ResolvableCap(
          package: 'analyzer',
          resolvable: Version(13, 3, 0),
          latest: Version(14, 7, 0),
          offerBreaking: preset.offerBreaking,
        ),
        ResolvableCap(
          package: 'test',
          resolvable: Version(1, 31, 1),
          latest: Version(1, 33, 0),
          offerBreaking: preset.offerBreaking,
        ),
      ];

      testData<RenovatePreset>(
        'is null without caps',
        RenovatePreset.values,
        dataToString: (preset) => preset.name,
        (preset) =>
            check(GlobalConfig.heldBackFooter(const [], preset: preset)).isNull,
      );

      test('lists all caps in a table', () {
        check(
            GlobalConfig.heldBackFooter(
              caps(.application),
              preset: .application,
            ),
          ).isNotNull()
          ..startsWith('## Held back updates\n')
          ..not(.it()..contains('Flutter'))
          ..contains('Breaking updates are offered anyway')
          ..endsWith(
            '| Package | Resolvable | Held back | Latest |\n'
            '|---|---|---|---|\n'
            '| `analyzer` | 13.3.0 | `>13.3.0 <14.0.0` | 14.7.0 |\n'
            '| `test` | 1.31.1 | `>1.31.1` | 1.33.0 |',
          );
      });

      test('holds back breaking updates for the library preset', () {
        check(GlobalConfig.heldBackFooter(caps(.library), preset: .library))
            .isNotNull()
          ..contains('the dependencies pinned by the Flutter SDK')
          ..not(.it()..contains('offered anyway'))
          ..contains('Breaking updates are held back as well')
          ..endsWith(
            '| `analyzer` | 13.3.0 | `>13.3.0` | 14.7.0 |\n'
            '| `test` | 1.31.1 | `>1.31.1` | 1.33.0 |',
          );
      });
    });
  });
}
