import '../../common/api/job_config.dart';
import '../../common/api/step_builder.dart';
import '../../common/api/working_directory_config.dart';
import '../../common/jobs/sdk_job_builder.dart';
import '../../common/steps/checkout_builder.dart';
import '../../common/steps/install_dart_test_tools_builder.dart';
import '../../types/expression.dart';
import '../../types/id.dart';
import '../../types/step.dart';

base mixin CheckUpdateRequiredConfig
    on JobConfig, SdkJobConfig, WorkingDirectoryConfig {}

class CheckUpdateRequiredBuilder implements StepBuilder {
  static const checkStepId = StepId('check_auto_update');
  static final hasOutdated = checkStepId.output('has_outdated');
  static final hasSecurityIssues = checkStepId.output('has_security_issues');

  final CheckUpdateRequiredConfig config;

  const CheckUpdateRequiredBuilder({required this.config});

  @override
  Iterable<Step> build() sync* {
    yield* const InstallDartTestToolsBuilder().build();
    yield* const CheckoutBuilder(
      fetchDepth: 0,
      persistCredentials: ExpressionOrValue.value(true),
    ).build();
    yield Step.run(
      name: 'Restore dart packages',
      run: '${config.pubTool} get',
      workingDirectory: config.workingDirectory.toString(),
    );
    yield Step.run(
      id: checkStepId,
      name: 'Check if updates are needed',
      run:
          '${config.pubTool} global run dart_test_tools:auto_update '
          "'${config.workingDirectory}'",
    );
  }
}
