import '../../common/api/step_builder.dart';
import '../../common/tools.dart';
import '../../types/expression.dart';
import '../../types/step.dart';

class SetupGCloudBuilder implements StepBuilder {
  final Expression firebaseProjectId;
  final Expression firebaseCredentials;

  const SetupGCloudBuilder({
    required this.firebaseProjectId,
    required this.firebaseCredentials,
  });

  @override
  Iterable<Step> build() => [
        Step.uses(
          name: 'Google Cloud Sign In',
          uses: Tools.googleGithubActionsAuth,
          withArgs: {
            'credentials_json': firebaseCredentials.toString(),
          },
        ),
        Step.uses(
          name: 'Setup gcloud',
          uses: Tools.googleGithubActionsSetupGcloud,
          withArgs: {
            'project_id': firebaseProjectId.toString(),
          },
        ),
      ];
}
