import '../../common/actions/install_tools_action_builder.dart';
import '../../common/api/job_config.dart';
import '../../common/api/step_builder.dart';
import '../../common/api/working_directory_config.dart';
import '../../common/contexts.dart';
import '../../common/inputs.dart';
import '../../common/jobs/sdk_job_builder.dart';
import '../../common/steps/checkout_builder.dart';
import '../../types/expression.dart';
import '../../types/id.dart';
import '../../types/step.dart';

base mixin CheckUpdateRequiredConfig
    on JobConfig, SdkJobConfig, WorkingDirectoryConfig {
  late final flutterCompat = inputContext(WorkflowInputs.flutterCompat);
}

class CheckUpdateRequiredBuilder implements StepBuilder {
  static const checkStepId = StepId('check_auto_update');
  static final needsUpdate = checkStepId.output('needs_update');

  final CheckUpdateRequiredConfig config;

  const CheckUpdateRequiredBuilder({required this.config});

  @override
  Iterable<Step> build() sync* {
    yield InstallToolsActionBuilder.step(withDartTestTools: true);
    yield* const CheckoutBuilder(
      fetchDepth: 0,
      persistCredentials: ExpressionOrValue.value(true),
    ).build();
    yield Step.run(
      name: 'Restore dart packages',
      run: '${config.pubTool} get',
      workingDirectory: config.workingDirectory.toString(),
    );
    final flutterCompatOption = Functions.case$([
      (config.flutterCompat, const ExpressionOrValue.value('--flutter-compat')),
    ], const ExpressionOrValue.value('--no-flutter-compat'));
    yield Step.run(
      id: checkStepId,
      name: 'Check if updates are needed',
      run:
          'auto-update '
          '--mode check '
          "--target '${config.workingDirectory}' "
          '$flutterCompatOption',
    );
  }
}
