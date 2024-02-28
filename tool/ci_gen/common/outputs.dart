import 'api/workflow_output.dart';

abstract base class WorkflowOutputs {
  const WorkflowOutputs._();

  static const releaseCreated = WorkflowOutput(
    name: 'releaseCreated',
    description: 'Holds a boolean value string ("true" or "false"), '
        'indicating whether a release was created or not.',
  );

  static const releaseVersion = WorkflowOutput(
    name: 'releaseVersion',
    description: 'Holds the version number of the created release, if the '
        'releaseCreated output is true. Otherwise, it is not set.',
  );

  static const enabledPlatforms = WorkflowOutput(
    name: 'enabledPlatforms',
    description: 'A JSON-encoded list of all platforms that this project can '
        'build/run for.',
  );
}
