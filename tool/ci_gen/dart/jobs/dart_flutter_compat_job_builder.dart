import '../../common/actions/install_tools_action_builder.dart';
import '../../common/api/job_config.dart';
import '../../common/api/working_directory_config.dart';
import '../../common/inputs.dart';
import '../../common/jobs/sdk_job_builder.dart';
import '../../common/steps/checkout_builder.dart';
import '../../flutter/jobs/flutter_sdk_job_builder_mixin.dart';
import '../../types/id.dart';
import '../../types/job.dart';
import '../../types/runs_on.dart';
import '../../types/step.dart';

final class DartFlutterCompatJobConfig(super.inputContext, super.secretContext)
    extends JobConfig
    with SdkJobConfig, FlutterSdkJobConfig, WorkingDirectoryConfig {
  late final flutterCompat = inputContext(WorkflowInputs.flutterCompat);
  late final withSubmodules = inputContext(WorkflowInputs.withSubmodules);
}

final class const DartFlutterCompatJobBuilder({required super.config})
    extends SdkJobBuilder<DartFlutterCompatJobConfig>
    with FlutterSdkJobBuilderMixin<DartFlutterCompatJobConfig> {
  @override
  JobId get id => const JobId('flutter_compat');

  @override
  Job build() => Job(
    name: 'Flutter compatibility',
    ifExpression: config.flutterCompat,
    runsOn: RunsOn.ubuntuLatest.id,
    steps: [
      ...buildSetupSdkSteps(),
      ...CheckoutBuilder(withSubmodules: config.withSubmodules).build(),
      // after the SDK setup, as dart install needs the dart of the flutter SDK
      InstallToolsActionBuilder.step(withDartTestTools: true),
      Step.run(
        name: 'Check flutter compatibility',
        run: 'flutter-compat',
        workingDirectory: config.workingDirectory.toString(),
      ),
    ],
  );
}
