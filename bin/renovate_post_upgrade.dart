import 'dart:io';

import 'package:args/args.dart';
import 'package:dart_test_tools/src/renovate/post_upgrade.dart';
import 'package:dart_test_tools/src/renovate/upgrade_data.dart';
import 'package:dart_test_tools/src/tools/github.dart';

void main(List<String> args) => Github.runZoned(() async {
  final parser =
      ArgParser(
          usageLineLength: stdout.hasTerminal ? stdout.terminalColumns : null,
        )
        ..addOption(
          'mode',
          abbr: 'm',
          allowed: PostUpgradeMode.values.map((m) => m.name),
          allowedHelp: {
            PostUpgradeMode.application.name:
                'Runs pub upgrade, so the lockfile gets regenerated.',
            PostUpgradeMode.library.name:
                'Runs pub get, so only the updated constraints get resolved.',
          },
          valueHelp: 'mode',
          help:
              'The <mode> to resolve dependencies with. '
              'The upgraded dependencies are read from the file in '
              '\$${UpgradeData.dataFileEnvVar}.',
        )
        ..addFlag('help', abbr: 'h', negatable: false, help: 'Show this help.');

  try {
    final options = parser.parse(args);

    if (options['help'] as bool) {
      stdout.writeln(parser.usage);
      return;
    }

    final modeName = options['mode'] as String?;
    if (modeName == null) {
      throw const FormatException('Option mode is mandatory.');
    }

    final upgrades = await UpgradeData.fromEnvironment();
    await PostUpgrade(mode: PostUpgradeMode.values.byName(modeName))(
      Directory.current,
      upgrades,
    );
  } on FormatException catch (e) {
    stderr
      ..writeln('Error: ${e.message}\n')
      ..writeln('Usage:')
      ..writeln(parser.usage);
    exitCode = 1;
  }
});
