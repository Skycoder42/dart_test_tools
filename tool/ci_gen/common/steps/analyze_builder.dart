import '../../types/expression.dart';
import '../../types/id.dart';
import '../../types/step.dart';
import '../api/job_config.dart';
import '../api/step_builder.dart';
import '../inputs.dart';
import 'project_setup_builder.dart';
import 'run_publish_builder.dart';

base mixin AnalyzeConfig on JobConfig, ProjectSetupConfig, RunPublishConfig {
  late final panaScoreThreshold = inputContext(
    WorkflowInputs.panaScoreThreshold,
  );

  @override
  late final withSubmodules = inputContext(WorkflowInputs.withSubmodules);
}

class AnalyzeBuilder implements StepBuilder {
  static const checkPublishStepId = StepId('checkPublish');
  static final checkPublishOutput = checkPublishStepId.output('publish');

  static const checkPlatformsStepId = StepId('checkPlatforms');
  static final platformsOutput = checkPlatformsStepId.output('platforms');

  final AnalyzeConfig config;
  final StepBuilderFn buildAnalyzeStep;

  const AnalyzeBuilder({required this.config, required this.buildAnalyzeStep});

  @override
  Iterable<Step> build() => [
    Step.run(
      name: 'Install pana',
      run: '${config.pubTool} global activate pana',
    ),
    ...ProjectSetupBuilder(config: config).build(),
    Step.run(
      id: checkPlatformsStepId,
      name: 'Check supported platforms',
      run:
          '''
set -eo pipefail
platforms=\$(yq '.platforms // {} | keys' -o=json -I=0 pubspec.yaml)
echo "Detected supported platforms as: \$platforms"
${platformsOutput.bashSetter(r'$platforms')}
''',
      workingDirectory: config.workingDirectory.toString(),
      shell: 'bash',
    ),
    ...buildAnalyzeStep(),
    Step.run(
      name: 'Run custom_lint',
      run: '${config.runTool} custom_lint',
      workingDirectory: config.workingDirectory.toString(),
    ),
    Step.run(
      name: 'Validate correct formatting',
      run:
          'dart format -onone --set-exit-if-changed '
          r"$(git ls-files '*.dart')",
      workingDirectory: config.workingDirectory.toString(),
    ),
    Step.run(
      id: checkPublishStepId,
      name: 'Check if package is publishable',
      run:
          '''
set -eo pipefail
publish_to=\$(cat pubspec.yaml | yq e ".publish_to" -)
if [[ "\$publish_to" == "none" ]]; then
  ${checkPublishOutput.bashSetter('false')}
else
  ${checkPublishOutput.bashSetter('true')}
fi
''',
      workingDirectory: config.workingDirectory.toString(),
      shell: 'bash',
    ),
    ...RunPublishBuilder(
      config: config,
      publishStepName: 'Test publishing configuration',
      publishArgs: '--dry-run',
      ifExpression: checkPublishOutput.expression.eq(
        const Expression.literal('true'),
      ),
    ).build(),
    Step.run(
      name: 'Validate pana score',
      ifExpression: checkPublishOutput.expression.eq(
        const Expression.literal('true'),
      ),
      run:
          '${config.pubTool} global run pana '
          '--exit-code-threshold ${config.panaScoreThreshold} .',
      workingDirectory: config.workingDirectory.toString(),
    ),
  ];
}
