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
  final Expression workingDirectory;
  final Expression buildRunner;
  final Expression buildRunnerArgs;
  @override
  final Expression platforms;
  final ICompileMatrix matrix;
  final String pubTool;
  final String runTool;

  CompileBuilder({
    required this.workingDirectory,
    required this.buildRunner,
    required this.buildRunnerArgs,
    required this.platforms,
    required this.matrix,
    required this.pubTool,
    required this.runTool,
  });

  @override
  Iterable<Step> build() => [
        ...ProjectSetupBuilder(
          workingDirectory: workingDirectory,
          buildRunner: buildRunner,
          buildRunnerArgs: buildRunnerArgs,
          releaseMode: true,
          pubTool: pubTool,
          runTool: runTool,
          ifExpression: _shouldRun,
        ).build(),
        Step.run(
          name: 'Compile executables',
          ifExpression: _shouldRun,
          run: '''
set -eo pipefail
mkdir -p build/bin
yq ".executables.[] | key" pubspec.yaml | while read executableName; do
  dartScript=\$(yq ".executables.[\\"\$executableName\\"] // \\"\$executableName\\"" pubspec.yaml)
  dart compile ${matrix.binaryType} ${matrix.compileArgs} "bin/\$dartScript.dart"
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
            'path': '$workingDirectory/build/bin/*',
            'retention-days': 3,
            'if-no-files-found': 'error',
          },
        ),
      ];

  Expression get _shouldRun => shouldRunExpression(matrix.platform);
}
