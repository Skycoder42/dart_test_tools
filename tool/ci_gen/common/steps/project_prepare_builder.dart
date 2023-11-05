import '../../types/expression.dart';
import '../../types/step.dart';
import '../api/step_builder.dart';
import '../tools.dart';

class ProjectPrepareBuilder implements StepBuilder {
  static const _runnerTemp = Expression('runner.temp');

  final String? titleSuffix;
  final Expression workingDirectory;
  final Expression? artifactDependencies;
  final Expression? buildRunner;
  final Expression? buildRunnerArgs;
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
    this.releaseMode = false,
    required this.pubTool,
    required this.runTool,
    this.ifExpression,
  });

  @override
  Iterable<Step> build() => [
        Step.run(
          name: 'Remove pubspec_overrides.yaml$_titleSuffix',
          ifExpression: ifExpression,
          run: 'find . -type f -name "pubspec_overrides.yaml" '
              r'-exec git rm -f {} \;',
          workingDirectory: workingDirectory.toString(),
          shell: 'bash',
        ),
        if (artifactDependencies != null) ...[
          Step.uses(
            name: 'Download artifacts',
            ifExpression: artifactDependencies!.ne(Expression.empty),
            uses: Tools.actionsDownloadArtifact,
            withArgs: {
              'path': '$_runnerTemp/.artifacts',
            },
          ),
          Step.run(
            name: 'Create pubspec_overrides.yaml for required packages',
            ifExpression: artifactDependencies!.ne(Expression.empty),
            shell: 'bash',
            run: '''
set -eo pipefail
touch pubspec_overrides.yaml
for package in ${artifactDependencies}; do
  yq -i \\
    ".dependency_overrides.\$package.path=\\"$_runnerTemp/.artifacts/package-\$package\\"" \\
    pubspec_overrides.yaml
done
''',
            workingDirectory: workingDirectory.toString(),
          ),
        ],
        Step.run(
          name: 'Restore dart packages$_titleSuffix',
          ifExpression: ifExpression,
          run: '$pubTool get',
          workingDirectory: workingDirectory.toString(),
        ),
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
}
