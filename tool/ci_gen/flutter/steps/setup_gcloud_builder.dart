import '../../common/api/job_config.dart';
import '../../common/api/step_builder.dart';
import '../../common/tools.dart';
import '../../types/expression.dart';
import '../../types/step.dart';

base mixin SetupGCloudConfig on JobConfig {
  late Expression firebaseProjectId;
  late Expression firebaseCredentials;
}

class SetupGCloudBuilder implements StepBuilder {
  final SetupGCloudConfig config;

  const SetupGCloudBuilder({
    required this.config,
  });

  @override
  Iterable<Step> build() => [
        Step.uses(
          name: 'Google Cloud Sign In',
          uses: Tools.googleGithubActionsAuth,
          withArgs: {
            'credentials_json': config.firebaseCredentials.toString(),
          },
        ),
        Step.uses(
          name: 'Setup gcloud',
          uses: Tools.googleGithubActionsSetupGcloud,
          withArgs: {
            'project_id': config.firebaseProjectId.toString(),
          },
        ),
      ];
}
