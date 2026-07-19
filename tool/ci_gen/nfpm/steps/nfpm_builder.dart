import '../../common/api/job_config.dart';
import '../../common/api/step_builder.dart';
import '../../common/api/working_directory_config.dart';
import '../../common/contexts.dart';
import '../../common/inputs.dart';
import '../../common/tools.dart';
import '../../types/expression.dart';
import '../../types/step.dart';

base mixin NfpmConfig on JobConfig, WorkingDirectoryConfig {
  late final bundleArtifact = inputContext(WorkflowInputs.bundleArtifact);
  late final additionalArtifacts = inputContext(
    WorkflowInputs.additionalArtifacts,
  );
  late final additionalArtifactsPath = inputContext(
    WorkflowInputs.additionalArtifactsPath,
  );
  late final packageType = inputContext(WorkflowInputs.packageType);
}

class NfpmBuilder implements StepBuilder {
  final NfpmConfig config;

  const NfpmBuilder({required this.config});

  @override
  Iterable<Step> build() => [
    Step.uses(
      name: 'Download bundle artifact',
      uses: Tools.actionsDownloadArtifact,
      withArgs: <String, dynamic>{
        'name': config.bundleArtifact.toString(),
        'path': '${Runner.temp}/bundle-archive',
      },
    ),
    const Step.run(
      name: 'Extract bundle',
      run: r'''
set -eo pipefail
mkdir -p "$RUNNER_TEMP/bundle"
tar -xavf "$RUNNER_TEMP"/bundle-archive/*.tar.xz -C "$RUNNER_TEMP/bundle" --strip-components=1
''',
      shell: 'bash',
    ),
    Step.uses(
      name: 'Download additional artifacts',
      ifExpression: config.additionalArtifacts.ne(Expression.empty),
      uses: Tools.actionsDownloadArtifact,
      withArgs: <String, dynamic>{
        'pattern': config.additionalArtifacts.toString(),
        'path': config.additionalArtifactsPath.toString(),
        'merge-multiple': true,
      },
    ),
    Step.run(
      name: 'Generate nfpm configuration from dart package',
      run:
          'generate-nfpm '
          '--input ${config.workingDirectory} '
          r'--bundle-root "$RUNNER_TEMP/bundle" '
          r'--output "$RUNNER_TEMP/nfpm"',
      shell: 'bash',
    ),
    Step.run(
      name: 'Build package with nfpm',
      run:
          '''
set -eo pipefail
mkdir -p "\$RUNNER_TEMP/out"
nfpm package -f "\$RUNNER_TEMP/nfpm/nfpm.yaml" -p '${config.packageType}' -t "\$RUNNER_TEMP/out"
''',
      shell: 'bash',
    ),
    Step.uses(
      name: 'Upload package to artifacts',
      uses: Tools.actionsUploadArtifact,
      withArgs: <String, dynamic>{
        'name': 'nfpm-package',
        'path': '${Runner.temp}/out/*',
        'retention-days': 3,
        'if-no-files-found': 'error',
      },
    ),
  ];
}
