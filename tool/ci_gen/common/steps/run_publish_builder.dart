import '../../types/expression.dart';
import '../../types/step.dart';
import '../api/job_config.dart';
import '../api/step_builder.dart';
import '../api/working_directory_config.dart';
import '../jobs/sdk_job_builder.dart';

base mixin RunPublishConfig
    on JobConfig, SdkJobConfig, WorkingDirectoryConfig {}

class RunPublishBuilder implements StepBuilder {
  final RunPublishConfig config;
  final String publishStepName;
  late String publishArgs;
  Expression? ifExpression;

  RunPublishBuilder({
    required this.config,
    required this.publishStepName,
    required this.publishArgs,
    this.ifExpression,
  });

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
