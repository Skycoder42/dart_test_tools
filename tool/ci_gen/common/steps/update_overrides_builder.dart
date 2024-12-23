import '../../types/expression.dart';
import '../../types/step.dart';
import '../api/job_config.dart';
import '../api/step_builder.dart';
import '../api/working_directory_config.dart';
import '../tools.dart';

base mixin UpdateOverridesConfig on JobConfig, WorkingDirectoryConfig {
  ExpressionOrValue get removePubspecOverrides =>
      const ExpressionOrValue.value(true);
  Expression? get artifactDependencies => null;
  ExpressionOrValue get localResolution => const ExpressionOrValue.value(true);
  Expression? get ifExpression => null;
}

class UpdateOverridesBuilder implements StepBuilder {
  final String titleSuffix;
  final String artifactTargetDir;
  final UpdateOverridesConfig config;

  UpdateOverridesBuilder({
    this.titleSuffix = '',
    required this.artifactTargetDir,
    required this.config,
  });

  @override
  Iterable<Step> build() => [
        if (config.removePubspecOverrides.rawValueOr(true))
          Step.run(
            name: 'Remove pubspec_overrides.yaml$titleSuffix',
            ifExpression: config.removePubspecOverrides.isExpression
                ? (config.removePubspecOverrides.asExpression &
                    config.ifExpression)
                : config.ifExpression,
            run: 'find . -type f -name "pubspec_overrides.yaml" '
                r'-exec git rm -f {} \;',
            workingDirectory: config.workingDirectory.toString(),
            shell: 'bash',
          ),
        if (config.artifactDependencies case final Expression artDeps) ...[
          Step.uses(
            name: 'Download artifacts',
            ifExpression: artDeps.ne(Expression.empty) & config.ifExpression,
            uses: Tools.actionsDownloadArtifact,
            withArgs: {
              'pattern': 'package-*',
              'path': '$artifactTargetDir/.artifacts',
            },
          ),
          Step.run(
            name: 'Create pubspec_overrides.yaml for artifact packages'
                '$titleSuffix',
            ifExpression: config.artifactDependencies!.ne(Expression.empty) &
                config.ifExpression,
            shell: 'bash',
            run: '''
set -eo pipefail
if [[ ! -f pubspec_overrides.yaml ]]; then
  yq '{"dependency_overrides": .dependency_overrides}' pubspec.yaml > pubspec_overrides.yaml
fi
for package in ${config.artifactDependencies}; do
  yq -i ".dependency_overrides.\$package.path=\\"$artifactTargetDir/.artifacts/package-\$package\\"" pubspec_overrides.yaml
done
''',
            workingDirectory: config.workingDirectory.toString(),
          ),
        ],
        if (config.localResolution.rawValueOr(true))
          Step.run(
            name: 'Switch to local resolution',
            ifExpression: config.localResolution.isExpression
                ? config.localResolution.asExpression & config.ifExpression
                : config.ifExpression,
            run: '''
set -eo pipefail
touch pubspec_overrides.yaml
yq -i '.resolution=null' pubspec_overrides.yaml
''',
            workingDirectory: config.workingDirectory.toString(),
            shell: 'bash',
          ),
      ];
}
