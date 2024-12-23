import '../../common/api/job_builder.dart';
import '../../common/api/job_config.dart';
import '../../common/steps/checkout_builder.dart';
import '../../types/expression.dart';
import '../../types/id.dart';
import '../../types/job.dart';
import '../steps/makedeb_builder.dart';
import '../steps/prepare_deb_builder.dart';

final class BuildDebJobConfig extends JobConfig with MakedebConfig {
  BuildDebJobConfig({
    required Expression workingDirectory,
  }) {
    this.workingDirectory = workingDirectory;
    expand();
  }
}

class BuildDebJobBuilder implements JobBuilder {
  final BuildDebJobConfig config;

  const BuildDebJobBuilder({
    required this.config,
  });

  @override
  JobId get id => const JobId('build_deb');

  @override
  Job build() => Job(
        name: 'Build deb package',
        runsOn: 'ubuntu-latest',
        steps: [
          ...const PrepareDebBuilder().build(),
          ...const CheckoutBuilder(
            path: 'src',
          ).build(),
          ...MakedebBuilder(config: config).build(),
        ],
      );
}
