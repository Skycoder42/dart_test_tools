import '../../types/expression.dart';
import '../../types/step.dart';
import '../api/job_config.dart';
import '../api/step_builder.dart';
import '../api/working_directory_config.dart';
import '../tools.dart';

base mixin UpdateOverridesConfig on JobConfig, WorkingDirectoryConfig {
  Expression? get artifactDependencies => null;
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
        name:
            'Create pubspec_overrides.yaml for artifact packages'
            '$titleSuffix',
        ifExpression:
            config.artifactDependencies!.ne(Expression.empty) &
            config.ifExpression,
        shell: 'bash',
        run:
            '''
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
  ];
}
