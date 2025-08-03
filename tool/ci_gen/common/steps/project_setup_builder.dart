import '../../types/expression.dart';
import '../../types/step.dart';
import '../actions/install_tools_action_builder.dart';
import '../api/job_config.dart';
import '../api/step_builder.dart';
import 'checkout_builder.dart';
import 'project_prepare_builder.dart';

base mixin ProjectSetupConfig on JobConfig, ProjectPrepareConfig {
  Expression? get withSubmodules => null;

  bool get withDartTestTools => false;
}

class ProjectSetupBuilder implements StepBuilder {
  final ProjectSetupConfig config;

  const ProjectSetupBuilder({required this.config});

  @override
  Iterable<Step> build() => [
    InstallToolsActionBuilder.step(withDartTestTools: config.withDartTestTools),
    ...CheckoutBuilder(withSubmodules: config.withSubmodules).build(),
    ...ProjectPrepareBuilder(config: config).build(),
  ];
}
