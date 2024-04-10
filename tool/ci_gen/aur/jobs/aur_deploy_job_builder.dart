import '../../common/api/job_builder.dart';
import '../../common/steps/checkout_builder.dart';
import '../../types/container.dart';
import '../../types/expression.dart';
import '../../types/id.dart';
import '../../types/job.dart';
import '../steps/clone_aur_builder.dart';
import '../steps/create_aur_package_builder.dart';
import '../steps/prepare_arch_builder.dart';
import '../steps/push_aur_builder.dart';

class AurDeployJobBuilder implements JobBuilder {
  final Expression dartSdkVersion;
  final Expression aurSshPrivateKey;

  const AurDeployJobBuilder({
    required this.dartSdkVersion,
    required this.aurSshPrivateKey,
  });

  @override
  JobId get id => const JobId('aur_deploy');

  @override
  Job build() => Job(
        name: 'Deploy to AUR',
        runsOn: 'ubuntu-latest',
        container: Container(image: 'archlinux:base-devel'),
        steps: [
          ...PrepareArchBuilder(
            dartSdkVersion: dartSdkVersion,
          ).build(),
          ...CheckoutBuilder(
            path: 'src',
          ).build(),
          ...CloneAurBuilder(
            aurSshPrivateKey: aurSshPrivateKey,
          ).build(),
          ...const CreateAurPackageBuilder().build(),
          ...const PushAurBuilder().build(),
        ],
      );
}
