import '../../common/api/step_builder.dart';
import '../../common/steps/project_setup_builder.dart';
import '../../common/tools.dart';
import '../../types/expression.dart';
import '../../types/id.dart';
import '../../types/step.dart';

class PackageBuilder implements StepBuilder {
  static const _getPackageNameStepId = StepId('get-package-name');
  static const _packageNameOutput =
      StepIdOutput(_getPackageNameStepId, 'package-name');

  final Expression workingDirectory;
  final Expression artifactDependencies;
  final Expression buildRunner;
  final Expression buildRunnerArgs;
  final Expression removePubspecOverrides;
  final String pubTool;
  final String runTool;

  PackageBuilder({
    required this.workingDirectory,
    required this.artifactDependencies,
    required this.buildRunner,
    required this.buildRunnerArgs,
    required this.removePubspecOverrides,
    required this.pubTool,
    required this.runTool,
  });

  @override
  Iterable<Step> build() => [
        ...ProjectSetupBuilder(
          workingDirectory: workingDirectory,
          artifactDependencies: artifactDependencies,
          buildRunner: buildRunner,
          buildRunnerArgs: buildRunnerArgs,
          removePubspecOverrides: removePubspecOverrides,
          pubTool: pubTool,
          runTool: runTool,
        ).build(),
        Step.run(
          id: _getPackageNameStepId,
          name: 'Get package name for artifact upload',
          run: _packageNameOutput.bashSetter(r'$(yq .name pubspec.yaml)'),
          workingDirectory: workingDirectory.toString(),
        ),
        Step.uses(
          name: 'Upload compiled binaries artifact',
          uses: Tools.actionsUploadArtifact,
          withArgs: <String, dynamic>{
            'name': 'package-${_packageNameOutput.expression}',
            'path': '''
$workingDirectory
!$workingDirectory/.*
!$workingDirectory/**/.*
''',
            'retention-days': 7,
            'if-no-files-found': 'error',
          },
        ),
      ];
}
