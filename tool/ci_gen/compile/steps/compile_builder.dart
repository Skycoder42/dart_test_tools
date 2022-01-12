import '../../common/api/step_builder.dart';
import '../../common/steps/project_setup_builder.dart';
import '../../types/expression.dart';
import '../../types/step.dart';

abstract class ICompileMatrix {
  Expression get platform;
  Expression get binaryType;
  Expression get compileArgs;
}

class CompileBuilder implements StepBuilder {
  final Expression repository;
  final Expression workingDirectory;
  final Expression buildRunner;
  final Expression targets;
  final ICompileMatrix matrix;
  final String pubTool;
  final String runTool;

  CompileBuilder({
    required this.repository,
    required this.workingDirectory,
    required this.buildRunner,
    required this.targets,
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
        ).build(),
        Step.run(
          name: 'Compile executables',
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
          uses: 'actions/upload-artifact@v2',
          withArgs: {
            'name': 'binaries-${matrix.platform}',
            'path': '$workingDirectory/bin/*.${matrix.binaryType}*',
          },
        ),
      ];
}
