import 'dart:io';

import 'package:dart_test_tools/src/common/config.dart';
import 'package:dart_test_tools/src/common/runner.dart';
import 'package:dart_test_tools/src/publish/config.dart';
import 'package:dart_test_tools/src/publish/publisher.dart';

Future<void> main(List<String> args) async {
  final runner = Runner();

  try {
    final publishConfig = PublishConfig.fromYaml(
      // TODO use config path?
      await DartTestToolsConfig.readYamlFor('pubspec.yaml', PublishConfig.key),
    );

    final publisher = Publisher(
      config: publishConfig,
      runner: runner,
    );

    await publisher.publish(args);
  } on ChildErrorException catch (e) {
    exitCode = e.exitCode;
  }
}
