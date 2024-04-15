import 'dart:convert';
import 'dart:io';

import 'package:yaml_writer/yaml_writer.dart';

import 'ci_gen/aur/aur_workflow.dart';
import 'ci_gen/common/api/workflow_builder.dart';
import 'ci_gen/compile/compile_workflow.dart';
import 'ci_gen/dart/dart_workflow.dart';
import 'ci_gen/deb/deb_workflow.dart';
import 'ci_gen/deploy/android/build_android_workflow.dart';
import 'ci_gen/deploy/deploy_workflow.dart';
import 'ci_gen/deploy/linux/build_linux_workflow.dart';
import 'ci_gen/docker/docker_workflow.dart';
import 'ci_gen/flutter/flutter_workflow.dart';
import 'ci_gen/package/package_workflow.dart';
import 'ci_gen/publish/publish_workflow.dart';
import 'ci_gen/release/release_workflow.dart';

Future<void> main() async {
  const workflows = [
    DartWorkflow(),
    FlutterWorkflow(),
    ReleaseWorkflow(),
    PublishWorkflow(),
    CompileWorkflow(),
    PackageWorkflow(),
    AurWorkflow(),
    DebWorkflow(),
    DockerWorkflow(),
    DeployWorkflow(),
    BuildAndroidWorkflow(),
    BuildLinuxWorkflow(),
  ];

  for (final workflow in workflows) {
    exitCode += await _writeWorkflowToFile(workflow);
  }
}

Future<int> _writeWorkflowToFile(WorkflowBuilder workflowBuilder) async {
  stdout.writeln('Generating ${workflowBuilder.name} workflow...');
  final writer = _createYamlWriter();

  final outFile =
      File('.github/workflows/${workflowBuilder.name}.yml').openWrite();
  final yqProc = await Process.start(
    'yq',
    const ['e', '-P'],
    runInShell: true,
  );
  final errFuture = yqProc.stderr.listen(stderr.add).asFuture<void>();
  final outFuture = yqProc.stdout.pipe(outFile);

  await Stream.value(writer.write(workflowBuilder.build()))
      .transform(utf8.encoder)
      .pipe(yqProc.stdin);

  await Future.wait([outFuture, errFuture]);

  return yqProc.exitCode;
}

YamlWriter _createYamlWriter() => YamlWriter(
      toEncodable: (dynamic data) {
        // ignore: avoid_dynamic_calls
        final dynamic jsonData = data.toJson != null ? data.toJson() : data;
        if (jsonData is Map) {
          return <dynamic, dynamic>{...jsonData}..remove('runtimeType');
        }
        return jsonData;
      },
    );
