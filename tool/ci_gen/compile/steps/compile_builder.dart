import '../../common/api/step_builder.dart';
import '../../common/steps/platforms_builder_mixin.dart';
import '../../common/steps/project_setup_builder.dart';
import '../../common/tools.dart';
import '../../types/expression.dart';
import '../../types/step.dart';

abstract class ICompileMatrix {
  Expression get platform;
  Expression get binaryType;
  Expression get compileArgs;
}

class CompileBuilder with PlatformsBuilderMixin implements StepBuilder {
  final Expression repository;
  final Expression workingDirectory;
  final Expression buildRunner;
  final Expression targets;
  @override
  final Expression platforms;
  final ICompileMatrix matrix;
  final String pubTool;
  final String runTool;

  CompileBuilder({
    required this.repository,
    required this.workingDirectory,
    required this.buildRunner,
    required this.targets,
    required this.platforms,
    required this.matrix,
    required this.pubTool,
    required this.runTool,
  });

  @override
  Iterable<Step> build() => [
        ...ProjectSetupBuilder(
          repository: repository,
          workingDirectory: workingDirectory,
          buildRunner: buildRunner,
          pubTool: pubTool,
          runTool: runTool,
          ifExpression: _shouldRun,
        ).build(),
        Step.run(
          name: 'Compile executables',
          ifExpression: _shouldRun,
          run: '''
set -e
echo '$targets' | jq -cr '.[]' | sed 's/\\r\$//' | while read target; do
  dart compile ${matrix.binaryType} ${matrix.compileArgs} "bin/\$target.dart"
done
''',
          workingDirectory: workingDirectory.toString(),
          shell: 'bash',
        ),
        Step.uses(
          name: 'Upload compiled binaries artifact',
          ifExpression: _shouldRun,
          uses: Tools.actionsUploadArtifact,
          withArgs: <String, dynamic>{
            'name': 'binaries-${matrix.platform}',
            'path': '$workingDirectory/bin/*.${matrix.binaryType}*',
          },
        ),
      ];

  Expression get _shouldRun => shouldRunExpression(matrix.platform);
}
