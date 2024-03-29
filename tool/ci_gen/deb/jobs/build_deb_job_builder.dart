import '../../common/api/job_builder.dart';
import '../../common/steps/checkout_builder.dart';
import '../../types/expression.dart';
import '../../types/job.dart';
import '../../types/id.dart';
import '../steps/makedeb_builder.dart';
import '../steps/prepare_deb_builder.dart';

class BuildDebJobBuilder implements JobBuilder {
  final Expression workingDirectory;

  const BuildDebJobBuilder({
    required this.workingDirectory,
  });

  @override
  JobId get id => const JobId('build_deb');

  @override
  Job build() => Job(
        name: 'Build deb package',
        runsOn: 'ubuntu-latest',
        steps: [
          ...const PrepareDebBuilder().build(),
          ...CheckoutBuilder(
            path: 'src',
          ).build(),
          ...MakedebBuilder(
            workingDirectory: workingDirectory,
          ).build(),
        ],
      );
}
