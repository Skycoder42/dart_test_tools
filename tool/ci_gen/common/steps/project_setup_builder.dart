import '../../types/expression.dart';
import '../../types/step.dart';
import '../api/job_config.dart';
import '../api/step_builder.dart';
import 'checkout_builder.dart';
import 'install_tools_builder.dart';
import 'project_prepare_builder.dart';

base mixin ProjectSetupConfig
    on JobConfig, InstallToolsConfig, ProjectPrepareConfig {
  Expression? get withSubmodules => null;
}

class ProjectSetupBuilder implements StepBuilder {
  final ProjectSetupConfig config;

  const ProjectSetupBuilder({required this.config});

  @override
  Iterable<Step> build() => [
    ...InstallToolsBuilder(config: config).build(),
    ...CheckoutBuilder(withSubmodules: config.withSubmodules).build(),
    ...ProjectPrepareBuilder(config: config).build(),
  ];
}
