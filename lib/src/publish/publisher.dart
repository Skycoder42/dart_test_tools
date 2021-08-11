import 'dart:io';

import '../common/runner.dart';
import 'config.dart';

class Publisher {
  static const _pubIgnorePath = '.pubignore';

  final PublishConfig config;
  final Runner runner;

  Publisher({
    required this.config,
    required this.runner,
  });

  Future<void> publish(List<String> args) async {
    final rootIgnoreFile = File(config.rootIgnore);
    File? pubIgnore;

    try {
      pubIgnore = await rootIgnoreFile.copy(_pubIgnorePath);
      for (final path in config.exclude.paths) {
        await runner('git', ['rm', path]);
      }

      await runner.pub(['publish', ...args]);
    } finally {
      await pubIgnore?.delete();
      for (final path in config.exclude.paths) {
        await runner('git', ['checkout', 'HEAD', path]);
      }
    }
  }
}
