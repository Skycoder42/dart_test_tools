import '../../common/api/job_builder.dart';
import '../../common/api/job_config.dart';
import '../../common/steps/checkout_builder.dart';
import '../../types/container.dart';
import '../../types/id.dart';
import '../../types/job.dart';
import '../steps/clone_aur_builder.dart';
import '../steps/create_aur_package_builder.dart';
import '../steps/prepare_arch_builder.dart';
import '../steps/push_aur_builder.dart';

final class AurDeployJobConfig extends JobConfig
    with CloneAurConfig, PrepareArchConfig {
  AurDeployJobConfig(super.inputContext, super.secretContext);
}

class AurDeployJobBuilder implements JobBuilder {
  final AurDeployJobConfig config;

  const AurDeployJobBuilder({required this.config});

  @override
  JobId get id => const JobId('aur_deploy');

  @override
  Job build() => Job(
    name: 'Deploy to AUR',
    runsOn: 'ubuntu-latest',
    container: const Container(image: 'archlinux:base-devel'),
    steps: [
      ...PrepareArchBuilder(config: config).build(),
      ...const CheckoutBuilder(path: 'src').build(),
      ...CloneAurBuilder(config: config).build(),
      ...const CreateAurPackageBuilder().build(),
      ...const PushAurBuilder().build(),
    ],
  );
}
