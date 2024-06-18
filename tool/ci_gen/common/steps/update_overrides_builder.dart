import '../../types/expression.dart';
import '../../types/step.dart';
import '../api/step_builder.dart';
import '../tools.dart';

class UpdateOverridesBuilder implements StepBuilder {
  final String titleSuffix;
  final Expression workingDirectory;
  final ExpressionOrValue removePubspecOverrides;
  final Expression? artifactDependencies;
  final ExpressionOrValue artifactTargetDir;
  final Expression? ifExpression;

  UpdateOverridesBuilder({
    this.titleSuffix = '',
    required this.workingDirectory,
    required this.removePubspecOverrides,
    required this.artifactDependencies,
    required this.artifactTargetDir,
    this.ifExpression,
  });

  @override
  Iterable<Step> build() => [
        if (removePubspecOverrides.rawValueOr(true))
          Step.run(
            name: 'Remove pubspec_overrides.yaml$titleSuffix',
            ifExpression: removePubspecOverrides.isExpression
                ? (removePubspecOverrides.asExpression & ifExpression)
                : ifExpression,
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
              'pattern': 'package-*',
              'path': '$artifactTargetDir/.artifacts',
            },
          ),
          Step.run(
            name: 'Create pubspec_overrides.yaml for artifact packages'
                '$titleSuffix',
            ifExpression:
                artifactDependencies!.ne(Expression.empty) & ifExpression,
            shell: 'bash',
            run: '''
set -eo pipefail
if [[ ! -f pubspec_overrides.yaml ]]; then
  yq '{"dependency_overrides": .dependency_overrides}' pubspec.yaml > pubspec_overrides.yaml
fi
for package in $artifactDependencies; do
  yq -i ".dependency_overrides.\$package.path=\\"$artifactTargetDir/.artifacts/package-\$package\\"" pubspec_overrides.yaml
done
''',
            workingDirectory: workingDirectory.toString(),
          ),
        ],
      ];
}
