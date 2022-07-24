import '../../common/api/job_builder.dart';
import '../../common/steps/checkout_builder.dart';
import '../../types/expression.dart';
import '../../types/id.dart';
import '../../types/job.dart';
import '../steps/prepare_arch_builder.dart';

class AurDeployJobBuilder implements JobBuilder {
  final Expression createAurUpdate;
  final Expression repository;

  const AurDeployJobBuilder({
    required this.createAurUpdate,
    required this.repository,
  });

  @override
  JobId get id => const JobId('aur_deploy');

  @override
  Job build() => Job(
        name: 'Deploy to AUR',
        ifExpression: createAurUpdate,
        runsOn: 'ubuntu-latest',
        container: 'archlinux:base-devel',
        steps: [
          ...PrepareArchBuilder().build(),
          ...CheckoutBuilder(
            repository: repository,
            path: 'src',
          ).build(),
        ],
      );
}
