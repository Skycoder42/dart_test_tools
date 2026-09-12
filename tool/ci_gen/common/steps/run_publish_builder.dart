import '../../types/expression.dart';
import '../../types/step.dart';
import '../api/job_config.dart';
import '../api/step_builder.dart';
import '../api/working_directory_config.dart';
import '../jobs/sdk_job_builder.dart';

base mixin RunPublishConfig on JobConfig, SdkJobConfig, WorkingDirectoryConfig;

class RunPublishBuilder({
  required final RunPublishConfig config,
  required final String publishStepName,
  required var String publishArgs,
  var Expression? ifExpression,
}) implements StepBuilder {
  @override
  Iterable<Step> build() => [
    Step.run(
      name: publishStepName,
      ifExpression: ifExpression,
      run: '${config.pubTool} publish $publishArgs',
      workingDirectory: config.workingDirectory.toString(),
    ),
  ];
}
