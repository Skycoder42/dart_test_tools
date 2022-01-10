import 'dart:io';

import 'package:yaml_writer/yaml_writer.dart';

import 'ci_gen/compile/compile_workflow.dart';
import 'ci_gen/dart/dart_workflow.dart';
import 'ci_gen/publish/publish_workflow.dart';
import 'ci_gen/types/workflow.dart';

Future<void> main() async {
  exitCode = await Stream.fromFutures([
    _writeWorkflowToFile('dart', DartWorkflow.buildWorkflow()),
    _writeWorkflowToFile('publish', PublishWorkflow.buildWorkflow()),
    _writeWorkflowToFile('compile', CompileWorkflow.buildWorkflow()),
  ]).reduce(
    (previous, element) => previous + element,
  );
}

Future<int> _writeWorkflowToFile(String name, Workflow workflow) async {
  final writer = _createYamlWriter();

  final outFile = File('.github/workflows/$name.yml').openWrite();
  final yqProc = await Process.start('yq', const ['e', '-P']);
  final errFuture = yqProc.stderr.listen(stdout.write).asFuture();
  final outFuture = yqProc.stdout.pipe(outFile);

  yqProc.stdin.write(writer.write(workflow));
  await yqProc.stdin.flush();
  await yqProc.stdin.close();

  await Future.wait([outFuture, errFuture]);

  return yqProc.exitCode;
}

YAMLWriter _createYamlWriter() {
  return YAMLWriter()
    ..toEncodable = (dynamic data) {
      // ignore: avoid_dynamic_calls
      final jsonData = data.toJson != null ? data.toJson() : data;
      if (jsonData is Map) {
        jsonData.remove('runtimeType');
      }
      return jsonData;
    };
}
