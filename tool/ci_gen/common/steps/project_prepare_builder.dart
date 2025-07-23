import '../../types/expression.dart';
import '../../types/id.dart';
import '../../types/step.dart';
import '../api/job_config.dart';
import '../api/step_builder.dart';
import '../contexts.dart';
import '../inputs.dart';
import '../jobs/sdk_job_builder.dart';
import 'update_overrides_builder.dart';

base mixin ProjectPrepareConfig
    on JobConfig, SdkJobConfig, UpdateOverridesConfig {
  bool get withBuildRunner => true;

  late final buildRunner = withBuildRunner
      ? inputContext(WorkflowInputs.buildRunner)
      : null;
  late final buildRunnerArgs = withBuildRunner
      ? inputContext(WorkflowInputs.buildRunnerArgs)
      : null;
  bool get releaseMode => false;
}

class ProjectPrepareBuilder implements StepBuilder {
  static const checkGenerateStepId = StepId('checkGenerate');
  static final generateOutput = checkGenerateStepId.output('generate');

  final String? titleSuffix;
  final ProjectPrepareConfig config;

  const ProjectPrepareBuilder({this.titleSuffix, required this.config});

  @override
  Iterable<Step> build() => [
    ...UpdateOverridesBuilder(
      titleSuffix: _titleSuffix,
      config: config,
      artifactTargetDir: Runner.temp.toString(),
    ).build(),
    Step.run(
      name: 'Restore dart packages$_titleSuffix',
      ifExpression: config.ifExpression,
      run: '${config.pubTool} get',
      workingDirectory: config.workingDirectory.toString(),
    ),
    if (_couldBeFlutter) ...[
      Step.run(
        id: checkGenerateStepId,
        name: 'Check if localizations generation is required',
        ifExpression: config.ifExpression != null
            ? config.ifExpression! & _onlyIfFlutter
            : _onlyIfFlutter,
        run:
            '''
          set -eo pipefail
          if [ -f l10n.yaml ]; then
            ${generateOutput.bashSetter('true')}
          else
            ${generateOutput.bashSetter('false')}
          fi
''',
        workingDirectory: config.workingDirectory.toString(),
        shell: 'bash',
      ),
      Step.run(
        name: 'Generate localization files',
        ifExpression:
            generateOutput.expression.eq(const Expression.literal('true')) &
            config.ifExpression &
            _onlyIfFlutter,
        run: 'flutter gen-l10n',
        workingDirectory: config.workingDirectory.toString(),
      ),
    ],
    if (config.buildRunner case final Expression buildRunner)
      Step.run(
        name: 'Create build files$_titleSuffix',
        ifExpression: buildRunner & config.ifExpression,
        run:
            '${config.runTool} build_runner build '
            '$_releaseArg'
            '${config.buildRunnerArgs ?? ''}',
        workingDirectory: config.workingDirectory.toString(),
      ),
  ];

  String get _titleSuffix => titleSuffix != null ? ' $titleSuffix' : '';

  String get _releaseArg => config.releaseMode ? '--release ' : '';

  bool get _couldBeFlutter => config.isFlutter.rawValueOr(true);

  Expression? get _onlyIfFlutter =>
      config.isFlutter.isExpression ? config.isFlutter.asExpression : null;
}
