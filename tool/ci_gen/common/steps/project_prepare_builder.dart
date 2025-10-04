import '../../types/expression.dart';
import '../../types/id.dart';
import '../../types/step.dart';
import '../api/job_config.dart';
import '../api/step_builder.dart';
import '../api/working_directory_config.dart';
import '../inputs.dart';
import '../jobs/sdk_job_builder.dart';

base mixin ProjectPrepareConfig
    on JobConfig, WorkingDirectoryConfig, SdkJobConfig {
  bool get withBuildRunner => true;
  bool get localResolution => false;
  bool get releaseMode => false;

  Expression? get ifExpression => null;

  late final buildRunner = withBuildRunner
      ? inputContext(WorkflowInputs.buildRunner)
      : null;
  late final buildRunnerArgs = withBuildRunner
      ? inputContext(WorkflowInputs.buildRunnerArgs)
      : null;

  late final Expression? buildDependencies = withBuildRunner && !localResolution
      ? inputContext(WorkflowInputs.buildDependencies)
      : null;
}

class ProjectPrepareBuilder implements StepBuilder {
  static const checkGenerateStepId = StepId('checkGenerate');
  static final generateOutput = checkGenerateStepId.output('generate');

  final String? titleSuffix;
  final ProjectPrepareConfig config;

  const ProjectPrepareBuilder({this.titleSuffix, required this.config});

  @override
  Iterable<Step> build() => [
    if (config.localResolution) ...[
      Step.run(
        name: 'Enforce local resolution',
        run: "echo 'resolution:' > pubspec_overrides.yaml",
        workingDirectory: config.workingDirectory.toString(),
        shell: 'bash',
      ),
    ],
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
    if (config.buildDependencies case final Expression buildDependencies)
      Step.run(
        name: 'Run build_runner for workspace dependencies',
        ifExpression:
            buildDependencies.ne(Expression.empty) & config.ifExpression,
        run:
            '''
set -euo pipefail
for package in $buildDependencies; do
  echo ">> Running build_runner for \$package"
  path=\$(
    dart pub workspace list --json \\
      | jq -r \\
        --arg package "\$package" \\
        '.packages[] | select(.name == \$package) | .path'
  )
  cd "\$path"
  ${config.runTool} build_runner build --delete-conflicting-outputs
done
''',
        workingDirectory: config.workingDirectory.toString(),
        shell: 'bash',
      ),
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
