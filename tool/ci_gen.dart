import 'dart:io';

import 'package:yaml_writer/yaml_writer.dart';

import 'ci_gen/dart/dart_workflow.dart';

Future<void> main() async {
  final writer = YAMLWriter()
    ..toEncodable = (dynamic data) {
      final jsonData = data.toJson != null ? data.toJson() : data;
      if (jsonData is Map) {
        jsonData.remove('runtimeType');
      }
      return jsonData;
    };

  final outFile = File('.github/workflows/test.yml').openWrite();
  final yqProc = await Process.start('yq', const ['e', '-P']);
  final errFuture = stderr.addStream(yqProc.stderr);
  final outFuture = yqProc.stdout.pipe(outFile);

  yqProc.stdin.write(writer.write(DartWorkflow.buildWorkflow()));
  await yqProc.stdin.flush();
  await yqProc.stdin.close();

  await Future.wait([
    outFuture,
    errFuture,
  ]);

  exitCode = await yqProc.exitCode;
}
