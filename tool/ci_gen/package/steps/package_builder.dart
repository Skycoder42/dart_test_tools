import '../../common/api/job_config.dart';
import '../../common/api/step_builder.dart';
import '../../common/inputs.dart';
import '../../common/steps/project_setup_builder.dart';
import '../../common/tools.dart';
import '../../types/id.dart';
import '../../types/step.dart';

base mixin PackageConfig on JobConfig, ProjectSetupConfig {
  @override
  late final withSubmodules = inputContext(WorkflowInputs.withSubmodules);
}

class PackageBuilder implements StepBuilder {
  static const _getPackageNameStepId = StepId('get-package-name');
  static const _packageNameOutput = StepIdOutput(
    _getPackageNameStepId,
    'package-name',
  );

  final PackageConfig config;

  PackageBuilder({required this.config});

  @override
  Iterable<Step> build() => [
    ...ProjectSetupBuilder(config: config).build(),
    Step.run(
      id: _getPackageNameStepId,
      name: 'Get package name for artifact upload',
      run: _packageNameOutput.bashSetter(r'$(yq .name pubspec.yaml)'),
      workingDirectory: config.workingDirectory.toString(),
    ),
    Step.uses(
      name: 'Upload compiled binaries artifact',
      uses: Tools.actionsUploadArtifact,
      withArgs: <String, dynamic>{
        'name': 'package-${_packageNameOutput.expression}',
        'path':
            '''
${config.workingDirectory}
!${config.workingDirectory}/.*
!${config.workingDirectory}/**/.*
''',
        'retention-days': 7,
        'if-no-files-found': 'error',
      },
    ),
  ];
}
