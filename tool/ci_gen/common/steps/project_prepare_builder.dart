import '../../types/expression.dart';
import '../../types/id.dart';
import '../../types/step.dart';
import '../api/step_builder.dart';
import '../contexts.dart';

class ProjectPrepareBuilder implements StepBuilder {
  static const checkGenerateStepId = StepId('checkGenerate');
  static final generateOutput = checkGenerateStepId.output('generate');

  final String? titleSuffix;
  final Expression workingDirectory;
  final Expression? artifactDependencies;
  final Expression? buildRunner;
  final Expression? buildRunnerArgs;
  final ExpressionOrValue removePubspecOverrides;
  final ExpressionOrValue isFlutter;
  final bool releaseMode;
  final String pubTool;
  final String runTool;
  final Expression? ifExpression;

  const ProjectPrepareBuilder({
    this.titleSuffix,
    required this.workingDirectory,
    this.artifactDependencies,
    this.buildRunner,
    this.buildRunnerArgs,
    this.removePubspecOverrides = const ExpressionOrValue.value(true),
    required this.isFlutter,
    this.releaseMode = false,
    required this.pubTool,
    required this.runTool,
    this.ifExpression,
  });

  @override
  Iterable<Step> build() => [
        if (removePubspecOverrides.rawValueOr(true))
          Step.run(
            name: 'Remove pubspec_overrides.yaml$_titleSuffix',
            ifExpression: removePubspecOverrides.isExpression
                ? (removePubspecOverrides.asExpression & ifExpression)
                : ifExpression,
            run: 'find . -type f -name "pubspec_overrides.yaml" '
                r'-exec git rm -f {} \;',
            workingDirectory: workingDirectory.toString(),
            shell: 'bash',
          ),
        if (artifactDependencies != null)
          Step.run(
            name: 'Create pubspec_overrides.yaml for artifact packages',
            ifExpression:
                artifactDependencies!.ne(Expression.empty) & ifExpression,
            shell: 'bash',
            run: '''
set -eo pipefail
touch pubspec_overrides.yaml
for package in $artifactDependencies; do
  yq -i ".dependency_overrides.\$package.path=\\"${Runner.temp}/.artifacts/package-\$package\\"" pubspec_overrides.yaml
done
''',
            workingDirectory: workingDirectory.toString(),
          ),
        Step.run(
          name: 'Restore dart packages$_titleSuffix',
          ifExpression: ifExpression,
          run: '$pubTool get',
          workingDirectory: workingDirectory.toString(),
        ),
        if (_couldBeFlutter) ...[
          Step.run(
            id: checkGenerateStepId,
            name: 'Check if localizations generation is required',
            ifExpression: ifExpression != null
                ? ifExpression! & _onlyIfFlutter
                : _onlyIfFlutter,
            run: generateOutput.bashSetter(
              "yq -r '.flutter.generate // false' pubspec.yaml",
              isCommand: true,
            ),
            workingDirectory: workingDirectory.toString(),
            shell: 'bash',
          ),
          Step.run(
            name: 'Generate localization files',
            ifExpression:
                generateOutput.expression.eq(const Expression.literal('true')) &
                    ifExpression &
                    _onlyIfFlutter,
            run: 'flutter gen-l10n',
            workingDirectory: workingDirectory.toString(),
          ),
        ],
        if (buildRunner != null)
          Step.run(
            name: 'Create build files$_titleSuffix',
            ifExpression: buildRunner! & ifExpression,
            run: '$runTool build_runner build '
                '$_releaseArg'
                '${buildRunnerArgs ?? ''}',
            workingDirectory: workingDirectory.toString(),
          ),
      ];

  String get _titleSuffix => titleSuffix != null ? ' $titleSuffix' : '';

  String get _releaseArg => releaseMode ? '--release ' : '';

  bool get _couldBeFlutter => isFlutter.rawValueOr(true);

  Expression? get _onlyIfFlutter =>
      isFlutter.isExpression ? isFlutter.asExpression : null;
}
