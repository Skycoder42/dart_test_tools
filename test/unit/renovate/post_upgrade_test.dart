import 'dart:async';
import 'dart:io';

import 'package:checks/checks.dart';
import 'package:dart_test_tools/src/pub/models/pub/workspace/workspace_info.dart';
import 'package:dart_test_tools/src/pub/models/pub/workspace/workspaces.dart';
import 'package:dart_test_tools/src/pub/models/renovate_config.dart';
import 'package:dart_test_tools/src/renovate/models/bump_level.dart';
import 'package:dart_test_tools/src/renovate/models/bump_rule.dart';
import 'package:dart_test_tools/src/renovate/models/renovate_upgrade.dart';
import 'package:dart_test_tools/src/renovate/post_upgrade.dart';
import 'package:dart_test_tools/src/test/test_data.dart';
import 'package:mockito/mockito.dart';
import 'package:path/path.dart' as path;
import 'package:pub_semver/pub_semver.dart';
import 'package:pubspec_parse/pubspec_parse.dart';
import 'package:test/scaffolding.dart';
import 'package:yaml_edit/yaml_edit.dart';

import '../_support/mocks.dart';

typedef _Edit = void Function(YamlEditor editor);

void main() {
  setUpAll(provideMockDummies);

  group('$PostUpgrade', () {
    final mockPubFactory = MockPubWrapperFactory();
    final mockRootPub = MockPubWrapper();
    final mockAPub = MockPubWrapper();
    final mockBPub = MockPubWrapper();
    final mockEditPub = MockPubWrapper();

    late Directory repoDir;
    late String repoPath;
    late Map<String, MockPubWrapper> pubs;

    /// Everything the mocks did, as `<mock>: <action>`, in call order.
    late List<String> events;

    /// The content of the pubspec edited by [mockEditPub].
    late String editedPubspec;

    /// The content of the analysis_options.yaml of [mockRootPub].
    late String analysisOptions;

    /// The events of one mock, without its name.
    List<String> eventsOf(String name) => [
      for (final event in events)
        if (event.startsWith('$name: ')) event.substring(name.length + 2),
    ];

    /// The changelog entries and version bump of a release of [name].
    List<String> release(String name, BumpLevel level, List<String> entries) =>
        [
          for (final entry in entries) 'cider log changed $entry',
          'cider bump ${level.name}',
          'cider version-sync',
          'cider release',
        ].map((e) => '$name: $e').toList();

    /// All cider events of all mocks.
    List<String> ciderEvents() =>
        events.where((e) => e.contains(': cider ')).toList();

    void stubPub(String name, MockPubWrapper mock) {
      when(mock.get()).thenAnswer((_) async => events.add('$name: get'));
      when(mock.upgrade())
          .thenAnswer((_) async => events.add('$name: upgrade'));
      when(mock.runShellCommand(any)).thenAnswer(
        (i) async => events.add('$name: sh ${i.positionalArguments.single}'),
      );
      when(mock.runBuildRunner())
          .thenAnswer((_) async => events.add('$name: build_runner'));
      when(mock.format()).thenAnswer((_) async => events.add('$name: format'));
      when(mock.fix()).thenAnswer((_) {
        events.add('$name: fix');
        return const Stream.empty();
      });
      when(mock.cider(any)).thenAnswer((i) async {
        final args = i.positionalArguments.single as List<String>;
        events.add('$name: cider ${args.join(' ')}');
      });
      when(mock.pubspecEdit(any)).thenAnswer((i) async {
        events.add('$name: pubspecEdit');
        final editor = YamlEditor(editedPubspec);
        (i.positionalArguments.single as _Edit)(editor);
        editedPubspec = editor.toString();
      });
      when(mock.analysisOptionsEdit(any)).thenAnswer((i) async {
        events.add('$name: analysisOptionsEdit');
        final editor = YamlEditor(analysisOptions);
        (i.positionalArguments.single as _Edit)(editor);
        analysisOptions = editor.toString();
      });
    }

    void stubConfig(RenovateConfig config) =>
        when(mockRootPub.renovateConfig()).thenAnswer((_) async => config);

    BumpRule rule({
      String manager = 'regex',
      Object name = 'native-lib',
      Object? updateTypes,
      String? bump,
      String message = 'Updated {{depName}} to {{newValue}}',
    }) => BumpRule.fromJson({
      'manager': manager,
      'name': name,
      'update_types': ?updateTypes,
      'bump': ?bump,
      'message': message,
    });

    void stubRules(List<BumpRule> rules) =>
        stubConfig(RenovateConfig(bumpRules: rules));

    Future<void> run(
      PostUpgradeMode mode,
      List<RenovateUpgrade> upgrades, {
      Directory? repoRoot,
    }) => PostUpgrade(mode: mode, pubFactory: mockPubFactory)(
      repoRoot ?? repoDir,
      upgrades,
    );

    setUp(() async {
      reset(mockPubFactory);
      reset(mockRootPub);
      reset(mockAPub);
      reset(mockBPub);
      reset(mockEditPub);

      repoDir = await Directory.systemTemp.createTemp();
      addTearDown(() => repoDir.delete(recursive: true));
      repoPath = await repoDir.resolveSymbolicLinks();
      events = [];
      editedPubspec = '';
      analysisOptions = '';

      pubs = {
        repoDir.path: mockRootPub,
        repoPath: mockRootPub,
        path.join(repoPath, 'packages', 'a'): mockAPub,
        path.join(repoPath, 'packages', 'b'): mockBPub,
      };
      when(mockPubFactory.create(any)).thenAnswer((i) async {
        final dir = i.positionalArguments.single as Directory;
        final pub = pubs[dir.path];
        if (pub == null) {
          throw StateError('Unexpected package ${dir.path}');
        }
        events.add('create ${dir.path}');
        return pub;
      });
      when(mockPubFactory.dart(any)).thenAnswer((i) {
        final dir = i.positionalArguments.single as Directory;
        events.add('dart ${dir.path}');
        return mockEditPub;
      });

      stubPub('root', mockRootPub);
      stubPub('a', mockAPub);
      stubPub('b', mockBPub);
      stubPub('edit', mockEditPub);

      stubConfig(const RenovateConfig());
      when(mockRootPub.workspaceList()).thenAnswer(
        (_) async => Workspaces(
          packages: [
            WorkspaceInfo(name: 'workspace', path: repoPath),
            WorkspaceInfo(
              name: 'a',
              path: path.join(repoPath, 'packages', 'a'),
            ),
            WorkspaceInfo(
              name: 'b',
              path: path.join(repoPath, 'packages', 'b'),
            ),
          ],
        ),
      );
      when(mockRootPub.pubspec()).thenAnswer(
        (_) async =>
            Pubspec('workspace', workspace: const ['packages/a', 'packages/b']),
      );
      when(mockAPub.pubspec()).thenAnswer((_) async => Pubspec('a'));
      when(mockBPub.pubspec())
          .thenAnswer((_) async => Pubspec('b', version: Version(1, 0, 0)));
      when(mockBPub.hasChangelog).thenReturn(true);
    });

    const pathUpgrade = RenovateUpgrade(
      manager: 'pub',
      depName: 'path',
      packageFile: 'packages/b/pubspec.yaml',
    );
    const sdkUpgrade = RenovateUpgrade(
      manager: 'pub',
      depName: 'dart',
      packageFile: 'packages/b/pubspec.yaml',
      currentValue: '^3.9.0',
      newValue: '^3.13.0',
    );
    const npmUpgrade = RenovateUpgrade(
      manager: 'npm',
      depName: 'renovate',
      packageFile: 'tool/renovate/package.json',
      currentValue: '44.164.5',
      newValue: '44.170.0',
    );
    const regexUpgrade = RenovateUpgrade(
      manager: 'regex',
      depName: 'flutter',
      packageFile: 'sbx/flutter/flutter.yaml',
      currentValue: '3.50.0',
      newValue: '3.51.0',
    );

    test('does nothing without upgrades', () async {
      await run(.library, const []);

      verifyZeroInteractions(mockPubFactory);
    });

    test('only non-pub upgrades without rules change nothing', () async {
      await run(.application, const [npmUpgrade]);

      check(events).deepEquals(['create ${repoDir.path}']);
    });

    group('resolves dependencies', () {
      test('with pub get in library mode', () async {
        await run(.library, const [pathUpgrade]);

        check(eventsOf('root')).contains('get');
        check(eventsOf('root')).not(.it()..contains('upgrade'));
      });

      test('with pub upgrade in application mode', () async {
        await run(.application, const [pathUpgrade]);

        check(eventsOf('root')).contains('upgrade');
        check(eventsOf('root')).not(.it()..contains('get'));
      });

      test('with pub get in application mode without pub upgrades', () async {
        stubConfig(
          const RenovateConfig(preBuildExtraManagers: .value('regex')),
        );

        await run(.application, const [regexUpgrade]);

        check(eventsOf('root')).contains('get');
        check(eventsOf('root')).not(.it()..contains('upgrade'));
      });
    });

    group('pre-build command', () {
      test('runs in the workspace root after resolving and before the '
          'auto fixes', () async {
        stubConfig(const RenovateConfig(preBuildCommand: 'echo ok'));
        when(mockRootPub.dependsOnBuildRunner()).thenAnswer((_) async => true);

        await run(.library, const [pathUpgrade]);

        check(eventsOf('root')).deepEquals([
          'get',
          'sh echo ok',
          'build_runner',
          'format',
          'fix',
          'format',
        ]);
      });

      test('is optional', () async {
        await run(.library, const [pathUpgrade]);

        verifyNever(mockRootPub.runShellCommand(any));
      });

      test('runs once for extra managers next to pub upgrades', () async {
        stubConfig(
          const RenovateConfig(
            preBuildExtraManagers: .value('regex'),
            preBuildCommand: 'echo ok',
          ),
        );

        await run(.library, const [regexUpgrade, pathUpgrade]);

        verify(mockRootPub.runShellCommand('echo ok')).called(1);
      });

      test('runs for extra managers without auto fixes or a release', () async {
        stubConfig(
          const RenovateConfig(
            preBuildExtraManagers: .list(['npm', 'regex']),
            preBuildCommand: 'echo ok',
          ),
        );

        await run(.library, const [regexUpgrade]);

        check(events).deepEquals([
          'create ${repoDir.path}',
          'root: get',
          'root: sh echo ok',
        ]);
      });

      test('ignores managers that are not listed', () async {
        stubConfig(
          const RenovateConfig(
            preBuildExtraManagers: .value('regex'),
            preBuildCommand: 'echo ok',
          ),
        );

        await run(.library, const [npmUpgrade]);

        check(events).deepEquals(['create ${repoDir.path}']);
      });

      test('stops on failures', () async {
        stubConfig(const RenovateConfig(preBuildCommand: 'exit 3'));
        when(mockRootPub.runShellCommand(any))
            .thenAnswer((_) async => throw Exception('exit code 3'));

        await check(run(.library, const [pathUpgrade])).throws<Exception>();

        verifyNever(mockRootPub.format());
        check(ciderEvents()).isEmpty;
      });
    });

    test('runs build_runner only if a package depends on it', () async {
      await run(.library, const [pathUpgrade]);

      verifyNever(mockRootPub.runBuildRunner());
    });

    group('analyzer plugins', () {
      setUp(() {
        when(mockRootPub.pubspec()).thenAnswer(
          (_) async => Pubspec(
            'workspace',
            workspace: const ['packages/a', 'packages/b'],
            devDependencies: {
              'path': HostedDependency(
                version: VersionConstraint.parse('^1.9.0'),
              ),
              'local': PathDependency('../local'),
            },
          ),
        );
      });

      test('are synced with the workspace root dependencies', () async {
        analysisOptions = 'plugins:\n  path: ^1.8.0\n';
        when(mockRootPub.analysisOptionsPlugins())
            .thenAnswer((_) async => {'path': '^1.8.0'});

        await run(.library, const [pathUpgrade]);

        check(analysisOptions).equals('plugins:\n  path: ^1.9.0\n');
        verifyNever(mockAPub.analysisOptionsPlugins());
        verifyNever(mockBPub.analysisOptionsPlugins());
      });

      test('are not edited if they are up to date', () async {
        analysisOptions = 'plugins:\n  path: ^1.9.0\n';
        when(mockRootPub.analysisOptionsPlugins())
            .thenAnswer((_) async => {'path': '^1.9.0'});

        await run(.library, const [pathUpgrade]);

        check(analysisOptions).equals('plugins:\n  path: ^1.9.0\n');
      });

      test('must be hosted dependencies', () async {
        when(mockRootPub.analysisOptionsPlugins())
            .thenAnswer((_) async => {'local': '^1.0.0'});

        await check(run(.library, const [pathUpgrade])).throws<Exception>(
          .it()..has('message', (e) => '$e').contains('local'),
        );
      });
    });

    group('widened constraints', () {
      RenovateUpgrade widened(String depName, String current, String next) =>
          pathUpgrade.copyWith(
            depName: depName,
            currentValue: current,
            newValue: next,
          );

      test('are merged before resolving the workspace', () async {
        editedPubspec = '''
dependencies:
  path: ^1.8.0 || ^1.9.0
dev_dependencies:
  meta:
    hosted: https://pub.dev
    version: ^1.15.0 || ^1.16.0
''';

        await run(.library, [
          widened('path', '^1.8.0', '^1.8.0 || ^1.9.0'),
          widened('meta', '^1.15.0', '^1.15.0 || ^1.16.0'),
        ]);

        check(editedPubspec)
          ..contains('  path: ">=1.8.0 <2.0.0"\n')
          ..contains('    version: ">=1.15.0 <2.0.0"\n');
        check(events.take(5)).deepEquals([
          'dart ${path.join(repoDir.path, 'packages', 'b')}',
          'edit: pubspecEdit',
          'dart ${path.join(repoDir.path, 'packages', 'b')}',
          'edit: pubspecEdit',
          'create ${repoDir.path}',
        ]);
      });

      test('are merged next to empty sections', () async {
        editedPubspec = '''
dependencies:
dev_dependencies:
  path: ^1.8.0 || ^1.9.0
''';

        await run(.library, [widened('path', '^1.8.0', '^1.8.0 || ^1.9.0')]);

        check(editedPubspec)
          ..contains('dependencies:\ndev_dependencies:\n')
          ..contains('  path: ">=1.8.0 <2.0.0"\n');
      });

      test('leave other constraints untouched', () async {
        editedPubspec = 'dependencies:\n  path: ^1.8.0 || ^1.9.0\n';

        await run(.library, [widened('path', '^1.8.0', '^1.8.0 || ^1.10.0')]);

        check(editedPubspec)
            .equals('dependencies:\n  path: ^1.8.0 || ^1.9.0\n');
      });

      test('are not touched without widened upgrades', () async {
        await run(.library, const [pathUpgrade]);

        verifyNever(mockPubFactory.dart(any));
      });
    });

    group('releases', () {
      test('add sdk entries and one dependencies entry', () async {
        await run(.library, [
          sdkUpgrade.copyWith(packageFile: 'packages/a/pubspec.yaml'),
          sdkUpgrade,
          sdkUpgrade,
          pathUpgrade,
        ]);

        check(ciderEvents()).deepEquals(
          release('b', .patch, [
            'Updated min sdk version to ^3.13.0',
            'Updated dependencies',
          ]),
        );
      });

      test('skip packages without version and changelog', () async {
        await run(.library, [
          sdkUpgrade.copyWith(packageFile: 'packages/a/pubspec.yaml'),
        ]);

        check(ciderEvents()).isEmpty;
      });

      test('skip packages without upgrades', () async {
        await run(.library, [
          sdkUpgrade.copyWith(packageFile: 'packages/a/pubspec.yaml'),
        ]);

        check(ciderEvents()).isEmpty;
      });

      test('skip the workspace root', () async {
        when(mockRootPub.hasChangelog).thenReturn(true);

        await run(.library, [sdkUpgrade.copyWith(packageFile: 'pubspec.yaml')]);

        check(ciderEvents()).isEmpty;
      });

      test('only bump packages without changelog', () async {
        when(mockBPub.hasChangelog).thenReturn(false);

        await run(.library, const [sdkUpgrade]);

        check(ciderEvents())
            .deepEquals(['b: cider bump patch', 'b: cider version-sync']);
      });

      test('only log changes of packages without version', () async {
        when(mockBPub.pubspec()).thenAnswer((_) async => Pubspec('b'));

        await run(.library, const [sdkUpgrade]);

        check(ciderEvents()).deepEquals([
          'b: cider log changed Updated min sdk version to ^3.13.0',
          'b: cider log changed Updated dependencies',
        ]);
      });

      test('ignore non-pub upgrades without rules', () async {
        await run(.library, const [npmUpgrade, pathUpgrade]);

        check(ciderEvents())
            .deepEquals(release('b', .patch, ['Updated dependencies']));
      });

      group('in library mode', () {
        RenovateUpgrade dependency(String depType, String next) => pathUpgrade
            .copyWith(depType: depType, currentValue: '^1.8.0', newValue: next);

        test('skip upgrades within the upper bound', () async {
          await run(.library, [dependency('dependencies', '^1.9.0')]);

          check(ciderEvents()).isEmpty;
        });

        test('skip dev dependencies with a new upper bound', () async {
          await run(.library, [dependency('dev_dependencies', '^2.0.0')]);

          check(ciderEvents()).isEmpty;
        });

        test('release dependencies with a new upper bound', () async {
          await run(.library, [dependency('dependencies', '^2.0.0')]);

          check(ciderEvents())
              .deepEquals(release('b', .patch, ['Updated dependencies']));
        });
      });

      test('release upgrades within the upper bound in application '
          'mode', () async {
        await run(.application, [
          pathUpgrade.copyWith(
            depType: 'dependencies',
            currentValue: '^1.8.0',
            newValue: '^1.9.0',
          ),
        ]);

        check(ciderEvents())
            .deepEquals(release('b', .patch, ['Updated dependencies']));
      });
    });

    group('bump rules', () {
      const nativeUpgrade = RenovateUpgrade(
        manager: 'regex',
        depName: 'native-lib',
        packageFile: 'packages/b/lib/native/version.txt',
        currentValue: '1.0.21+202610010000',
        newValue: '1.0.22+202611181006',
        newVersion: '1.0.22',
        updateType: 'patch',
      );
      const nativeEntry = 'Updated native-lib to 1.0.22+202611181006';

      testData<PostUpgradeMode>(
        'release a package for a matching non-pub upgrade with pub get and '
        'without auto fixes',
        PostUpgradeMode.values,
        dataToString: (mode) => mode.name,
        (mode) async {
          stubRules([rule()]);

          await run(mode, const [nativeUpgrade]);

          check(eventsOf('root')).deepEquals(['get']);
          check(ciderEvents()).deepEquals(release('b', .patch, [nativeEntry]));
        },
      );

      testData<BumpLevel>(
        'bumps create a release of their level',
        BumpLevel.values,
        dataToString: (level) => level.name,
        (level) async {
          stubRules([rule(bump: level.name)]);

          await run(.library, const [nativeUpgrade]);

          check(ciderEvents()).deepEquals(release('b', level, [nativeEntry]));
        },
      );

      test('the biggest bump of rules and pub upgrades wins', () async {
        stubRules([rule(bump: 'minor')]);

        await run(.library, const [nativeUpgrade, sdkUpgrade]);

        check(ciderEvents()).deepEquals(
          release('b', .minor, [
            'Updated min sdk version to ^3.13.0',
            nativeEntry,
            'Updated dependencies',
          ]),
        );
      });

      test('pub upgrades keep their patch bump next to a build bump', () async {
        stubRules([rule(bump: 'build')]);

        await run(.application, const [nativeUpgrade, pathUpgrade]);

        check(ciderEvents()).deepEquals(
          release('b', .patch, [nativeEntry, 'Updated dependencies']),
        );
      });

      test('rules force a release of pub upgrades in library mode', () async {
        stubRules([rule(bump: 'build')]);

        await run(.library, [
          nativeUpgrade,
          pathUpgrade.copyWith(
            depType: 'dependencies',
            currentValue: '^1.8.0',
            newValue: '^1.9.0',
          ),
        ]);

        check(ciderEvents()).deepEquals(
          release('b', .build, [nativeEntry, 'Updated dependencies']),
        );
      });

      test('rules can match pub upgrades', () async {
        stubRules([
          rule(
            manager: 'pub',
            name: 'path',
            bump: 'minor',
            message: 'Bundled path {{newValue}}',
          ),
        ]);

        await run(.library, [
          pathUpgrade.copyWith(
            depType: 'dependencies',
            currentValue: '^1.8.0',
            newValue: '^1.9.0',
          ),
        ]);

        check(ciderEvents()).deepEquals(
          release('b', .minor, ['Bundled path ^1.9.0', 'Updated dependencies']),
        );
      });

      test('grouped upgrades create one entry per distinct message', () async {
        stubRules([
          rule(name: ['native-lib', 'other-lib']),
          rule(
            updateTypes: 'digest',
            bump: 'build',
            message: 'Rebuilt {{depName}} ({{newDigestShort}})',
          ),
        ]);

        await run(.library, [
          nativeUpgrade,
          nativeUpgrade.copyWith(packageFile: 'packages/b/lib/native/x.cmake'),
          nativeUpgrade.copyWith(
            depName: 'other-lib',
            newValue: '2.0.0',
            packageFile: 'packages/b/native/other.txt',
          ),
        ]);

        check(ciderEvents()).deepEquals(
          release('b', .patch, [nativeEntry, 'Updated other-lib to 2.0.0']),
        );
      });

      test('the first matching rule wins', () async {
        stubRules([
          rule(
            updateTypes: ['digest', 'pinDigest'],
            bump: 'build',
            message: 'Rebuilt {{depName}} ({{newDigestShort}})',
          ),
          rule(bump: 'major', message: 'Catch all'),
        ]);

        await run(.library, [
          nativeUpgrade.copyWith(
            newValue: '1.0.21',
            newDigestShort: 'abc1234',
            updateType: 'digest',
          ),
        ]);

        check(ciderEvents())
            .deepEquals(release('b', .build, ['Rebuilt native-lib (abc1234)']));
      });

      test('only rules of the workspace root are used', () async {
        await run(.library, const [nativeUpgrade]);

        verifyNever(mockBPub.renovateConfig());
        check(ciderEvents()).isEmpty;
      });

      test('run the pre-build command of extra managers before releasing '
          'without auto fixes', () async {
        stubConfig(
          RenovateConfig(
            preBuildExtraManagers: const .value('regex'),
            preBuildCommand: 'echo ok',
            bumpRules: [rule()],
          ),
        );

        await run(.library, const [nativeUpgrade]);

        check(events.where((e) => !e.startsWith('create '))).deepEquals([
          'root: get',
          'root: sh echo ok',
          ...release('b', .patch, [nativeEntry]),
        ]);
      });

      test('do not run the pre-build command of other managers', () async {
        stubConfig(
          RenovateConfig(preBuildCommand: 'echo ok', bumpRules: [rule()]),
        );

        await run(.library, const [nativeUpgrade]);

        verifyNever(mockRootPub.runShellCommand(any));
        check(ciderEvents()).deepEquals(release('b', .patch, [nativeEntry]));
      });

      test(
        'missing placeholder values fail before changing anything',
        () async {
          stubRules([rule(message: 'Digest {{newDigest}}')]);

          await check(run(.library, const [nativeUpgrade])).throws<Exception>(
            .it()
              ..has(
                'message',
                (e) => '$e',
              ).containsInOrder(['regex/native-lib', 'newDigest']),
          );

          check(events).deepEquals(['create ${repoDir.path}']);
        },
      );

      testData<(String, RenovateUpgrade)>(
        'release nothing for',
        [
          (
            'upgrades matching no rule',
            nativeUpgrade.copyWith(depName: 'typo'),
          ),
          (
            'upgrades of packages without version or changelog',
            nativeUpgrade.copyWith(
              packageFile: 'packages/a/native/version.txt',
            ),
          ),
          (
            'upgrades of the workspace root',
            nativeUpgrade.copyWith(packageFile: 'tool/native/version.txt'),
          ),
        ],
        dataToString: (d) => d.$1,
        (d) async {
          stubRules([rule()]);

          await run(.library, [d.$2]);

          check(ciderEvents()).isEmpty;
        },
      );

      group('warnings', () {
        /// The warnings logged while running [upgrades] in library mode.
        Future<List<String>> warnings(List<RenovateUpgrade> upgrades) async {
          final lines = <String>[];
          await runZoned(
            () => run(.library, upgrades),
            zoneSpecification: ZoneSpecification(
              print: (_, _, _, line) => lines.add(line),
            ),
          );
          return lines.where((l) => l.startsWith('::warning::')).toList();
        }

        test('are logged for non-pub upgrades matching no rule', () async {
          stubRules([rule()]);

          final logged = await warnings([
            nativeUpgrade,
            nativeUpgrade.copyWith(depName: 'typo'),
          ]);

          check(logged).single.equals(
            '::warning::regex upgrade of typo in '
            'packages/b/lib/native/version.txt matched no bump rule',
          );
        });

        test('are not logged for pub upgrades matching no rule', () async {
          stubRules([rule()]);

          check(await warnings(const [pathUpgrade])).isEmpty;
        });

        test('are not logged without rules', () async {
          check(await warnings([nativeUpgrade.copyWith(depName: 'typo')]))
              .isEmpty;
        });
      });

      group('attribute non-pub upgrades', () {
        void checkReleased() => check(ciderEvents()).deepEquals(
          release('b', .patch, [nativeEntry, 'Updated dependencies']),
        );

        setUp(() => stubRules([rule()]));

        test('to the closest workspace package', () async {
          await run(.library, [
            nativeUpgrade.copyWith(
              packageFile: 'packages/b/tool/native/version.txt',
            ),
            pathUpgrade,
          ]);

          checkReleased();
        });

        test('through a symlinked repository root', () async {
          final linkDir = await Directory.systemTemp.createTemp();
          addTearDown(() => linkDir.delete(recursive: true));
          final link = await Link(path.join(linkDir.path, 'repo'))
              .create(repoDir.path);
          pubs[link.path] = mockRootPub;

          await run(.library, const [
            nativeUpgrade,
            pathUpgrade,
          ], repoRoot: Directory(link.path));

          checkReleased();
        });

        test('with non-normalized package files', () async {
          await run(.library, [
            nativeUpgrade.copyWith(
              packageFile: './packages/b/lib/../lib/native/version.txt',
            ),
            pathUpgrade.copyWith(packageFile: './packages//b/pubspec.yaml'),
          ]);

          checkReleased();
        });
      });
    });

    group('releaseLevel', () {
      const withinBound = RenovateUpgrade(
        manager: 'pub',
        depName: 'path',
        packageFile: 'pubspec.yaml',
        depType: 'dependencies',
        currentValue: '^1.2.0',
        newValue: '^1.3.0',
      );
      const newBound = RenovateUpgrade(
        manager: 'pub',
        depName: 'path',
        packageFile: 'pubspec.yaml',
        depType: 'dependencies',
        currentValue: '^1.2.0',
        newValue: '^2.0.0',
      );

      testData<PostUpgradeMode>(
        'is null without upgrades and rules',
        PostUpgradeMode.values,
        dataToString: (mode) => mode.name,
        (mode) =>
            check(PostUpgrade.releaseLevel(mode, const [], const [])).isNull,
      );

      test('is patch for pub upgrades in application mode', () {
        check(
          PostUpgrade.releaseLevel(.application, const [withinBound], const []),
        ).equals(BumpLevel.patch);
      });

      test('is patch for pub upgrades with a new bound in library mode', () {
        check(PostUpgrade.releaseLevel(.library, const [newBound], const []))
            .equals(BumpLevel.patch);
      });

      test('is null for pub upgrades within bounds in library mode', () {
        check(PostUpgrade.releaseLevel(.library, const [withinBound], const []))
            .isNull;
      });

      test('is the biggest rule level without pub upgrades', () {
        check(
          PostUpgrade.releaseLevel(.library, const [], const [
            BumpLevel.build,
            BumpLevel.breaking,
            BumpLevel.minor,
          ]),
        ).equals(BumpLevel.breaking);
      });

      test('is the biggest of pub and rule levels', () {
        check(
          PostUpgrade.releaseLevel(
            .library,
            const [newBound],
            const [BumpLevel.build],
          ),
        ).equals(BumpLevel.patch);
        check(
          PostUpgrade.releaseLevel(
            .application,
            const [withinBound],
            const [BumpLevel.major],
          ),
        ).equals(BumpLevel.major);
        check(
          PostUpgrade.releaseLevel(
            .library,
            const [withinBound],
            const [BumpLevel.build],
          ),
        ).equals(BumpLevel.build);
      });
    });

    group('mergeWidenedConstraint', () {
      test('merges caret ranges into one range', () {
        check(PostUpgrade.mergeWidenedConstraint('^13.3.0 || ^14.0.0'))
          ..equals(VersionConstraint.parse('>=13.3.0 <15.0.0') as VersionRange)
          ..has('string', (c) => c.toString()).equals('>=13.3.0 <15.0.0');
      });

      test('covers gaps and keeps unbounded ends', () {
        check(
          PostUpgrade.mergeWidenedConstraint('>=1.0.0 <2.0.0 || >=3.0.0')
              .toString(),
        ).equals('>=1.0.0');
        check(PostUpgrade.mergeWidenedConstraint('^2.0.0 || <1.5.0').toString())
            .equals('<3.0.0');
      });

      test('throws on unsupported parts', () {
        check(() => PostUpgrade.mergeWidenedConstraint('^1.0.0 || foo'))
            .throws<FormatException>();
      });
    });

    group('changesUpperBound', () {
      String describe((String?, String?) d) => '${d.$1} -> ${d.$2}';

      testData<(String?, String?)>(
        'keeps the bound',
        const [
          ('^1.2.0', '^1.3.0'),
          ('^1.8.0', '>=1.9.0 <2.0.0'),
          ('>=1.0.0 <3.0.0', '>=2.0.0 <3.0.0'),
        ],
        dataToString: describe,
        (d) => check(PostUpgrade.changesUpperBound(d.$1, d.$2)).isFalse,
      );

      testData<(String?, String?)>(
        'changes the bound',
        const [
          ('^1.2.0', '^2.0.0'),
          ('^0.14.0', '^0.15.0'),
          ('^13.3.0', '^13.3.0 || ^14.0.0'),
          ('^1.0.0', '>=1.0.0'),
          ('1.2.3', '1.2.4'),
        ],
        dataToString: describe,
        (d) => check(PostUpgrade.changesUpperBound(d.$1, d.$2)).isTrue,
      );

      testData<(String?, String?)>(
        'assumes a changed bound for missing or unparsable values',
        const [(null, '^1.0.0'), ('^1.0.0', null), ('main', 'v2')],
        dataToString: describe,
        (d) => check(PostUpgrade.changesUpperBound(d.$1, d.$2)).isTrue,
      );
    });

    group('requiresVersionBump', () {
      RenovateUpgrade dep(String? depType, String current, String next) =>
          RenovateUpgrade(
            manager: 'pub',
            depName: 'pkg',
            packageFile: 'pubspec.yaml',
            depType: depType,
            currentValue: current,
            newValue: next,
          );

      test('is false without upgrades', () {
        check(PostUpgrade.requiresVersionBump(const [])).isFalse;
      });

      testData<String>(
        'is true for sdk upgrades',
        const ['dart', 'flutter'],
        (sdk) => check(
          PostUpgrade.requiresVersionBump([
            RenovateUpgrade(
              manager: 'pub',
              depName: sdk,
              packageFile: 'pubspec.yaml',
              currentValue: '^3.9.0',
              newValue: '^3.10.0',
            ),
          ]),
        ).isTrue,
      );

      test('is false for dependencies within their bound', () {
        check(
          PostUpgrade.requiresVersionBump([
            dep('dependencies', '^1.2.0', '^1.3.0'),
          ]),
        ).isFalse;
      });

      test('is true for dependencies with a new bound', () {
        check(
          PostUpgrade.requiresVersionBump([
            dep('dependencies', '^1.2.0', '^2.0.0'),
          ]),
        ).isTrue;
      });

      test('ignores dev dependencies', () {
        check(
          PostUpgrade.requiresVersionBump([
            dep('dev_dependencies', '^1.2.0', '^2.0.0'),
          ]),
        ).isFalse;
      });

      test('treats a missing depType as dependency', () {
        check(PostUpgrade.requiresVersionBump([dep(null, '^1.2.0', '^2.0.0')]))
            .isTrue;
      });

      test('is true if any upgrade requires it', () {
        check(
          PostUpgrade.requiresVersionBump([
            dep('dependencies', '^1.2.0', '^1.3.0'),
            dep('dev_dependencies', '^1.0.0', '^2.0.0'),
            dep('dependencies', '^0.1.0', '^0.2.0'),
          ]),
        ).isTrue;
      });
    });
  });
}
