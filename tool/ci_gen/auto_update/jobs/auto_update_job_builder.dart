import '../../common/api/job_config.dart';
import '../../common/api/working_directory_config.dart';
import '../../common/contexts.dart';
import '../../common/jobs/sdk_job_builder.dart';
import '../../common/secrets.dart';
import '../../common/steps/checkout_builder.dart';
import '../../common/steps/install_tools_builder.dart';
import '../../common/tools.dart';
import '../../flutter/jobs/flutter_sdk_job_builder_mixin.dart';
import '../../types/expression.dart';
import '../../types/id.dart';
import '../../types/job.dart';
import '../../types/runs_on.dart';
import '../../types/step.dart';

final class AutoUpdateJobConfig extends JobConfig
    with
        SdkJobConfig,
        FlutterSdkJobConfig,
        InstallToolsConfig,
        WorkingDirectoryConfig {
  AutoUpdateJobConfig(super.inputContext, super.secretContext);

  late final githubToken = secretContext(WorkflowSecrets.githubToken);
}

final class AutoUpdateJobBuilder extends SdkJobBuilder<AutoUpdateJobConfig>
    with FlutterSdkJobBuilderMixin {
  static const testCheckStepId = StepId('check_for_flutter_test');
  static final flutterTestWasInstalled = testCheckStepId.output(
    'was_installed',
  );

  AutoUpdateJobBuilder({required super.config});

  @override
  JobId get id => const JobId('auto-update');

  @override
  Job build() => Job(
    name: 'Automatic dependency updates',
    runsOn: RunsOn.ubuntuLatest.id,
    permissions: const {'contents': 'write', 'pull-requests': 'write'},
    steps: [
      ...buildSetupSdkSteps(),
      ...InstallToolsBuilder(config: config).build(),
      ...const CheckoutBuilder(
        fetchDepth: 0,
        persistCredentials: ExpressionOrValue.value(true),
      ).build(),
      Step.run(
        name: 'Restore dart packages',
        run: '${config.pubTool} get',
        workingDirectory: config.workingDirectory.toString(),
      ),
      Step.run(
        name: 'Update SDK versions',
        run: r'''
set -euo pipefail

dart_version=$(dart --version | cut -d: -f2 | cut '-d(' -f1 | xargs)
flutter_version=$(flutter --version | grep Flutter | cut -d ' ' -f2 | xargs)

for pubspec in $(find . -name pubspec.yaml); do
  echo "Updating SDK versions in $pubspec"
  sed -i "s/sdk: \([^\"]*\)/sdk: ^$dart_version/" "$pubspec"
  if grep -q 'flutter:' "$pubspec"; then
    sed -i "s/flutter: .*/flutter: '>=$flutter_version'/" "$pubspec"
  fi
done
''',
        workingDirectory: config.workingDirectory.toString(),
      ),
      Step.run(
        id: testCheckStepId,
        name: 'Install flutter_test if needed',
        run:
            '''
set -euo pipefail

if ${config.pubTool} deps --json | jq '.packages | any(.name == "flutter_test")' | grep -q true; then
  ${flutterTestWasInstalled.bashSetter('false')}
else
  ${config.pubTool} add 'dev:flutter_test:{sdk: flutter}'
  ${flutterTestWasInstalled.bashSetter('true')}
fi
''',
        workingDirectory: config.workingDirectory.toString(),
      ),
      Step.run(
        name: 'Upgrade all dependencies',
        run:
            '''
set -euo pipefail

echo '```' > ${Runner.temp}/update_log.md
${config.pubTool} upgrade --major-versions --tighten | tee -a ${Runner.temp}/update_log.md
echo '```' >> ${Runner.temp}/update_log.md
''',
        workingDirectory: config.workingDirectory.toString(),
      ),
      Step.run(
        name: 'Remove flutter_test',
        ifExpression: flutterTestWasInstalled.expression.eq(
          const Expression.literal('true'),
        ),
        run: '${config.pubTool} remove flutter_test',
        workingDirectory: config.workingDirectory.toString(),
      ),
      Step.run(
        name: 'Regenerate lockfiles',
        ifExpression: flutterTestWasInstalled.expression.eq(
          const Expression.literal('true'),
        ),
        run: '${config.pubTool} upgrade',
        workingDirectory: config.workingDirectory.toString(),
      ),
      Step.run(
        name: 'Display changes',
        run: 'git diff',
        workingDirectory: config.workingDirectory.toString(),
      ),
      Step.uses(
        name: 'Create pull request',
        uses: Tools.peterEvansCreatePullRequest,
        withArgs: {
          'branch': 'automatic-dependency-updates',
          'commit-message': 'Automatic dependency updates',
          'title': 'Automatic dependency updates',
          'body-path': '${Runner.temp}/update_log.md',
          'token': config.githubToken.toString(),
        },
      ),
    ],
  );
}
