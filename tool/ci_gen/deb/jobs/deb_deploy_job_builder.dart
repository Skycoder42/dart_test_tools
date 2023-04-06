import '../../common/api/job_builder.dart';
import '../../common/steps/checkout_builder.dart';
import '../../types/expression.dart';
import '../../types/job.dart';
import '../../types/id.dart';
import '../steps/prepare_deb_builder.dart';

class DebDeployJobBuilder implements JobBuilder {
  final Expression createDebPackage;

  const DebDeployJobBuilder({
    required this.createDebPackage,
  });

  @override
  JobId get id => const JobId('deb_deploy');

  @override
  Job build() => Job(
        name: 'Build deb package',
        ifExpression: createDebPackage,
        runsOn: 'ubuntu-latest',
        steps: [
          ...PrepareDebBuilder().build(),
          ...CheckoutBuilder(
            path: 'src',
          ).build(),
        ],
      );
}
