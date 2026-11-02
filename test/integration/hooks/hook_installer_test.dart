@TestOn('dart-vm')
library;

import 'dart:io';

import 'package:dart_test_tools/src/hooks/hook_installer.dart';
import 'package:dart_test_tools/src/hooks/hook_scripts.dart';
import 'package:path/path.dart';
import 'package:test/test.dart';

import 'git_test_repo.dart';

void main() {
  group('$HookInstaller', () {
    late GitTestRepo repo;

    File hook(String name, [String hooksDir = '.git/hooks']) =>
        repo.file(join(hooksDir, name));

    Future<List<File>> install({
      Directory? workingDirectory,
      bool flutterCompat = true,
      bool force = false,
    }) => HookInstaller(
      workingDirectory ?? repo.dir,
      environment: repo.env,
    ).install(flutterCompat: flutterCompat, force: force);

    void expectInstalled(File file, String content) {
      expect(file.readAsStringSync(), content);
      if (!Platform.isWindows) {
        expect(file.statSync().modeString(), startsWith('rwxr-xr-x'));
      }
    }

    setUp(() async {
      repo = await GitTestRepo.create();
    });

    tearDown(() => repo.dispose());

    test('writes both hooks into a fresh repo', () async {
      final files = await install();

      expect(files.map((f) => basename(f.path)), ['pre-commit', 'pre-push']);
      expectInstalled(hook('pre-commit'), HookScripts.preCommit);
      expectInstalled(
        hook('pre-push'),
        HookScripts.prePush(flutterCompat: true),
      );
      expect(
        hook('pre-commit').readAsStringSync(),
        contains(HookScripts.marker),
      );
    });

    test('writes into a relative core.hooksPath and creates it', () async {
      await repo.git(['config', 'core.hooksPath', '.githooks']);

      await install();

      expectInstalled(hook('pre-commit', '.githooks'), HookScripts.preCommit);
      expect(hook('pre-commit').existsSync(), isFalse);
    });

    test('resolves the hooks directory when run from a subdirectory', () async {
      await repo.git(['config', 'core.hooksPath', '.githooks']);
      final subDir = Directory(join(repo.dir.path, 'lib', 'src'));
      await subDir.create(recursive: true);

      await install(workingDirectory: subDir);

      expectInstalled(hook('pre-commit', '.githooks'), HookScripts.preCommit);
      expect(Directory(join(subDir.path, '.githooks')).existsSync(), isFalse);
    });

    test('writes into the main repository from a worktree', () async {
      await repo.git(['commit', '--allow-empty', '-m', 'x']);
      final worktree = Directory(join(repo.root.path, 'wt'));
      await repo.git(['worktree', 'add', worktree.path]);

      await install(workingDirectory: worktree);

      expectInstalled(hook('pre-commit'), HookScripts.preCommit);
    });

    test('overwrites hooks it generated before', () async {
      await repo.writeFile(
        '.git/hooks/pre-push',
        '#!/bin/sh\n${HookScripts.marker}\nexit 0\n',
      );

      await install();

      expectInstalled(
        hook('pre-push'),
        HookScripts.prePush(flutterCompat: true),
      );
    });

    test('refuses to replace foreign hooks and writes nothing', () async {
      const foreign = '#!/bin/sh\nexec other-tool\n';
      await repo.writeFile('.git/hooks/pre-push', foreign);

      await expectLater(
        install(),
        throwsA(
          isA<ForeignHooksException>()
              .having(
                (e) => e.hooks.map((file) => basename(file.path)),
                'hooks',
                ['pre-push'],
              )
              .having((e) => e.toString(), 'toString', contains('--force')),
        ),
      );
      expect(hook('pre-push').readAsStringSync(), foreign);
      expect(hook('pre-commit').existsSync(), isFalse);
    });

    test('replaces foreign hooks with force', () async {
      await repo.writeFile('.git/hooks/pre-push', '#!/bin/sh\nexit 0\n');

      await install(force: true);

      expectInstalled(
        hook('pre-push'),
        HookScripts.prePush(flutterCompat: true),
      );
    });

    test('leaves out the flutter compat check if disabled', () async {
      await install(flutterCompat: false);

      expectInstalled(
        hook('pre-push'),
        HookScripts.prePush(flutterCompat: false),
      );
      expect(
        hook('pre-push').readAsStringSync(),
        isNot(contains('flutter_compat')),
      );
    });

    test('a second run yields identical files', () async {
      await install();
      final preCommit = hook('pre-commit').readAsStringSync();
      final prePush = hook('pre-push').readAsStringSync();

      await install();

      expect(hook('pre-commit').readAsStringSync(), preCommit);
      expect(hook('pre-push').readAsStringSync(), prePush);
    });

    test('throws outside of a git repository', () async {
      final noRepo = Directory(join(repo.root.path, 'no-repo'));
      await noRepo.create();

      await expectLater(
        HookInstaller(
          noRepo,
          environment: {...repo.env, 'GIT_CEILING_DIRECTORIES': repo.root.path},
        ).install(flutterCompat: true, force: false),
        throwsA(isA<Exception>()),
      );
    });

    group('warnings', () {
      late Directory flutterBin;

      // Only the directory that contains git, so the real flutter of the
      // machine running the tests is not found.
      String gitOnlyPath() {
        final gitName = Platform.isWindows ? 'git.exe' : 'git';
        return Platform.environment[pathKey]!
            .split(pathSeparator)
            .firstWhere((dir) => File(join(dir, gitName)).existsSync());
      }

      Future<List<String>> warnings({
        bool flutterCompat = true,
        bool withFlutter = true,
      }) {
        return HookInstaller(
          repo.dir,
          environment: {
            ...repo.env,
            pathKey: [
              gitOnlyPath(),
              if (withFlutter) flutterBin.path,
            ].join(pathSeparator),
          },
        ).warnings(flutterCompat: flutterCompat);
      }

      setUp(() async {
        final flutterName = Platform.isWindows ? 'flutter.bat' : 'flutter';
        flutterBin = Directory(join(repo.root.path, 'flutter-bin'));
        await writeExecutable(File(join(flutterBin.path, flutterName)), '');
        expect(
          File(join(gitOnlyPath(), flutterName)).existsSync(),
          isFalse,
          reason: 'flutter must not be next to git',
        );
      });

      test('warns about a missing pubspec.yaml', () async {
        final result = await warnings();

        expect(result, [contains('dart_test_tools')]);
      });

      test('warns about a missing dart_test_tools dependency', () async {
        await repo.writeFile('pubspec.yaml', '''
name: test_package
environment:
  sdk: ^3.9.0
dependencies:
  path: ^1.9.0
''');

        final result = await warnings();

        expect(result, [contains('dart_test_tools')]);
      });

      test('accepts dart_test_tools as dev dependency', () async {
        await repo.writeFile('pubspec.yaml', '''
name: test_package
environment:
  sdk: ^3.9.0
dev_dependencies:
  dart_test_tools: ^8.0.0
''');

        expect(await warnings(), isEmpty);
      });

      test('accepts dart_test_tools as dependency', () async {
        await repo.writeFile('pubspec.yaml', '''
name: test_package
environment:
  sdk: ^3.9.0
dependencies:
  dart_test_tools: ^8.0.0
''');

        expect(await warnings(), isEmpty);
      });

      test('warns about a missing flutter', () async {
        await repo.writeFile('pubspec.yaml', '''
name: test_package
environment:
  sdk: ^3.9.0
dev_dependencies:
  dart_test_tools: ^8.0.0
''');

        final result = await warnings(withFlutter: false);

        expect(result, [
          allOf(contains('flutter'), contains('--no-flutter-compat')),
        ]);
      });

      test('warns about nothing if flutter compat is disabled', () async {
        expect(
          await warnings(flutterCompat: false, withFlutter: false),
          isEmpty,
        );
      });
    });
  }, timeout: const Timeout(Duration(minutes: 5)));
}
