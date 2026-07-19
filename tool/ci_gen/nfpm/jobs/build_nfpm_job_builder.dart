import '../../common/api/job_config.dart';
import '../../common/api/working_directory_config.dart';
import '../../common/jobs/sdk_job_builder.dart';
import '../../common/steps/checkout_builder.dart';
import '../../dart/jobs/dart_sdk_job_builder_mixin.dart';
import '../../types/id.dart';
import '../../types/job.dart';
import '../steps/nfpm_builder.dart';
import '../steps/prepare_nfpm_builder.dart';

final class BuildNfpmJobConfig extends JobConfig
    with SdkJobConfig, WorkingDirectoryConfig, DartSdkJobConfig, NfpmConfig {
  BuildNfpmJobConfig(super.inputContext, super.secretContext);
}

final class BuildNfpmJobBuilder extends SdkJobBuilder<BuildNfpmJobConfig>
    with DartSdkJobBuilderMixin<BuildNfpmJobConfig> {
  @override
  JobId get id => const JobId('build_nfpm');

  BuildNfpmJobBuilder({required super.config});

  @override
  Job build() => Job(
    name: 'Build nfpm package',
    runsOn: 'ubuntu-latest',
    steps: [
      ...buildSetupSdkSteps(),
      ...const PrepareNfpmBuilder().build(),
      ...const CheckoutBuilder().build(),
      ...NfpmBuilder(config: config).build(),
    ],
  );
}
