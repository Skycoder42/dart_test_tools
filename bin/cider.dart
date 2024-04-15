import 'dart:io';

import 'package:cider/cider.dart';
import 'package:dart_test_tools/src/cider/version_sync_plugin.dart';

Future<void> main(List<String> args) {
  final cli = CiderCli();
  cli.addCommand(VersionSyncCommand(cli.console));
  return cli.run(args).then((code) => exitCode = code);
}
