import 'dart:convert';
import 'dart:io';

import 'package:yaml_writer/yaml_writer.dart';

import 'ci_gen/aur/aur_workflow.dart';
import 'ci_gen/compile/compile_workflow.dart';
import 'ci_gen/dart/dart_workflow.dart';
import 'ci_gen/docker/docker_workflow.dart';
import 'ci_gen/flutter/flutter_workflow.dart';
import 'ci_gen/publish/publish_workflow.dart';
import 'ci_gen/types/workflow.dart';

Future<void> main() async {
  exitCode += await _writeWorkflowToFile(
    'dart',
    DartWorkflow.buildWorkflow(),
  );
  exitCode += await _writeWorkflowToFile(
    'flutter',
    FlutterWorkflow.buildWorkflow(),
  );
  exitCode += await _writeWorkflowToFile(
    'publish',
    PublishWorkflow.buildPublishWorkflow(),
  );
  exitCode += await _writeWorkflowToFile(
    'create-release',
    PublishWorkflow.buildCreateReleaseWorkflow(),
  );
  exitCode += await _writeWorkflowToFile(
    'pub-publish',
    PublishWorkflow.buildPubPublishWorkflow(),
  );
  exitCode += await _writeWorkflowToFile(
    'compile',
    CompileWorkflow.buildWorkflow(),
  );
  exitCode += await _writeWorkflowToFile(
    'aur',
    AurWorkflow.buildWorkflow(),
  );
  exitCode += await _writeWorkflowToFile(
    'docker',
    DockerWorkflow.buildWorkflow(),
  );
}

Future<int> _writeWorkflowToFile(String name, Workflow workflow) async {
  stdout.writeln('Generating $name workflow...');
  final writer = _createYamlWriter();

  final outFile = File('.github/workflows/$name.yml').openWrite();
  final yqProc = await Process.start(
    'yq',
    const ['e', '-P'],
    runInShell: true,
  );
  final errFuture = yqProc.stderr.listen(stderr.add).asFuture<void>();
  final outFuture = yqProc.stdout.pipe(outFile);

  await Stream.value(writer.write(workflow))
      .transform(utf8.encoder)
      .pipe(yqProc.stdin);

  await Future.wait([outFuture, errFuture]);

  return yqProc.exitCode;
}

YAMLWriter _createYamlWriter() => YAMLWriter()
  ..toEncodable = (dynamic data) {
    // ignore: avoid_dynamic_calls
    final dynamic jsonData = data.toJson != null ? data.toJson() : data;
    if (jsonData is Map) {
      return <dynamic, dynamic>{...jsonData}..remove('runtimeType');
    }
    return jsonData;
  };
