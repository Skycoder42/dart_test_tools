@TestOn('dart-vm')
library;

import 'dart:io';

import 'package:dart_test_tools/src/hooks/hook_scripts.dart';
import 'package:path/path.dart';
import 'package:test/test.dart';

import 'git_test_repo.dart';

const _unformatted = 'void main(){print( "x" );}\n';
const _formatted = '''
void main() {
  print("x");
}
''';

void main() {
  group('pre-commit', () {
    late GitTestRepo repo;

    Future<int> commitCount() async {
      final result = await repo.git([
        'rev-list',
        '--count',
        '--all',
      ], check: false);
      return result.exitCode == 0
          ? int.parse((result.stdout as String).trim())
          : 0;
    }

    Future<ProcessResult> commit() =>
        repo.git(['commit', '-m', 'x'], check: false);

    setUp(() async {
      repo = await GitTestRepo.create();
      await writeExecutable(
        repo.file(join('.git', 'hooks', 'pre-commit')),
        HookScripts.preCommit,
      );
    });

    tearDown(() => repo.dispose());

    test('no dart files staged commits', () async {
      await repo.writeFile('README.md', '# readme\n');
      await repo.git(['add', '.']);

      final result = await commit();

      expect(result.exitCode, 0, reason: '${result.stdout}${result.stderr}');
      expect(await commitCount(), 1);
    });

    test('formatted dart file commits', () async {
      await repo.writeFile('lib/a.dart', _formatted);
      await repo.git(['add', '.']);

      final result = await commit();

      expect(result.exitCode, 0, reason: '${result.stdout}${result.stderr}');
      expect(await commitCount(), 1);
    });

    test('unformatted staged file aborts the commit and is formatted '
        'in the working tree only', () async {
      await repo.writeFile('lib/a.dart', _unformatted);
      await repo.git(['add', '.']);

      final result = await commit();

      expect(result.exitCode, isNot(0));
      expect(result.stderr, contains('lib/a.dart'));
      expect(await commitCount(), 0);
      expect(repo.file('lib/a.dart').readAsStringSync(), _formatted);
      final staged = await repo.git(['show', ':lib/a.dart']);
      expect(staged.stdout, _unformatted);
    });

    test('renamed unformatted file is formatted under its new name', () async {
      await repo.writeFile('lib/a.dart', _formatted);
      await repo.git(['add', '.']);
      expect((await commit()).exitCode, 0);

      await repo.git(['mv', 'lib/a.dart', 'lib/b.dart']);
      await repo.writeFile('lib/b.dart', _unformatted);
      await repo.git(['add', '.']);

      final result = await commit();

      expect(result.exitCode, isNot(0));
      expect(await commitCount(), 1);
      expect(repo.file('lib/b.dart').readAsStringSync(), _formatted);
    });

    test('staged deletion is ignored', () async {
      await repo.writeFile('lib/a.dart', _formatted);
      await repo.git(['add', '.']);
      expect((await commit()).exitCode, 0);

      await repo.git(['rm', 'lib/a.dart']);

      final result = await commit();

      expect(result.exitCode, 0, reason: '${result.stdout}${result.stderr}');
      expect(await commitCount(), 2);
    });

    test('handles paths with spaces and umlauts', () async {
      const path = 'lib/ä ö/fïle name.dart';
      await repo.writeFile(path, _unformatted);
      await repo.git(['add', '.']);

      final result = await commit();

      expect(result.exitCode, isNot(0));
      expect(await commitCount(), 0);
      expect(repo.file(path).readAsStringSync(), _formatted);
    });

    test('syntax error aborts the commit', () async {
      await repo.writeFile('lib/a.dart', 'void main() {\n');
      await repo.git(['add', '.']);

      final result = await commit();

      expect(result.exitCode, isNot(0));
      expect(await commitCount(), 0);
      expect('${result.stdout}${result.stderr}', contains('lib/a.dart'));
    });
  }, timeout: const Timeout(Duration(minutes: 5)));
}
