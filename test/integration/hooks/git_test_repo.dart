import 'dart:convert';
import 'dart:io';

import 'package:path/path.dart';
import 'package:test/test.dart';

class GitTestRepo._(final Directory dir, final Map<String, String> env) {
  static Future<GitTestRepo> create() async {
    final dir = await Directory.systemTemp.createTemp();
    final gitConfig = File(join(dir.path, '.gitconfig-test'));
    await gitConfig.writeAsString('');

    final repoDir = Directory(join(dir.path, 'repo'));
    await repoDir.create();

    final repo = GitTestRepo._(repoDir, {
      'GIT_CONFIG_GLOBAL': gitConfig.path,
      'GIT_CONFIG_NOSYSTEM': '1',
      'GIT_AUTHOR_NAME': 'Test',
      'GIT_AUTHOR_EMAIL': 'test@example.com',
      'GIT_COMMITTER_NAME': 'Test',
      'GIT_COMMITTER_EMAIL': 'test@example.com',
    });
    await repo.git(['init', '-b', 'main']);
    return repo;
  }

  Directory get root => dir.parent;

  File file(String path) => File(join(dir.path, path));

  Future<ProcessResult> git(
    List<String> args, {
    bool check = true,
    String? workingDirectory,
  }) async {
    final result = await Process.run(
      'git',
      args,
      workingDirectory: workingDirectory ?? dir.path,
      environment: env,
      stdoutEncoding: utf8,
      stderrEncoding: utf8,
    );
    if (check) {
      expect(
        result.exitCode,
        0,
        reason: 'git ${args.join(' ')}\n${result.stdout}${result.stderr}',
      );
    }
    return result;
  }

  Future<void> writeFile(String path, String content) async {
    final file = this.file(path);
    await file.parent.create(recursive: true);
    await file.writeAsString(content);
  }

  Future<void> dispose() => root.delete(recursive: true);
}

// Git Bash of the GitHub Actions Windows images, see
// https://github.com/actions/runner-images/blob/main/images/windows/Windows2025-Readme.md
const _gitBash = r'C:\Program Files\Git\bin\bash.exe';

String get shellExecutable => Platform.isWindows ? _gitBash : 'sh';

Future<void> writeExecutable(File file, String content) async {
  await file.parent.create(recursive: true);
  await file.writeAsString(content);
  if (!Platform.isWindows) {
    final result = await Process.run('chmod', ['755', file.path]);
    expect(result.exitCode, 0, reason: '${result.stderr}');
  }
}

String get pathKey => Platform.environment.keys.firstWhere(
  (key) => key.toUpperCase() == 'PATH',
  orElse: () => 'PATH',
);

String get pathSeparator => Platform.isWindows ? ';' : ':';

Map<String, String> prependPath(String directory) {
  final path = Platform.environment[pathKey];
  return {pathKey: path == null ? directory : '$directory$pathSeparator$path'};
}
