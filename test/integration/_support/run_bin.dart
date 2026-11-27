import 'dart:convert';
import 'dart:io';

import 'package:path/path.dart';
import 'package:test/scaffolding.dart';

final class BinRunner(final String name) {
  late File _kernel;

  this {
    Directory? compileDir;

    setUpAll(() async {
      final dir = compileDir = await Directory.systemTemp.createTemp();
      _kernel = File(join(dir.path, '$name.dill'));
      final result = await Process.run(
        Platform.resolvedExecutable,
        [
          'compile',
          'kernel',
          absolute('bin', '$name.dart'),
          '-o',
          _kernel.path,
        ],
        stdoutEncoding: utf8,
        stderrEncoding: utf8,
      );
      if (result.exitCode != 0) {
        throw Exception('Failed to compile bin/$name.dart: ${result.output}');
      }
    });

    tearDownAll(() => compileDir?.delete(recursive: true));
  }

  Future<ProcessResult> call(
    List<String> args, {
    required Directory workingDirectory,
    Map<String, String>? environment,
  }) => Process.run(
    Platform.resolvedExecutable,
    [_kernel.path, ...args],
    workingDirectory: workingDirectory.path,
    environment: environment,
    stdoutEncoding: utf8,
    stderrEncoding: utf8,
  );
}

extension ProcessResultOutputX on ProcessResult {
  String get output => '$stdout$stderr';
}
