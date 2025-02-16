import '../../types/expression.dart';
import '../../types/step.dart';
import '../api/job_config.dart';
import '../api/step_builder.dart';
import '../contexts.dart';
import 'checkout_builder.dart';
import 'project_prepare_builder.dart';

base mixin ProjectSetupConfig on JobConfig, ProjectPrepareConfig {
  Expression? get withSubmodules => null;

  bool get skipYqInstall => false;
}

class ProjectSetupBuilder implements StepBuilder {
  final ProjectSetupConfig config;

  const ProjectSetupBuilder({required this.config});

  @override
  Iterable<Step> build() => [
    Step.run(
      name: 'Install scoop',
      ifExpression: Runner.os.eq(const Expression.literal('Windows')),
      shell: 'pwsh',
      run: r'''
iex "& {$(irm get.scoop.sh)} -RunAsAdmin"
Join-Path (Resolve-Path ~).Path "scoop\shims" >> $Env:GITHUB_PATH
''',
    ),
    if (!config.skipYqInstall) ...[
      Step.run(
        name: 'Install yq (Windows)',
        ifExpression: Runner.os.eq(const Expression.literal('Windows')),
        run: 'scoop install yq',
      ),
      Step.run(
        name: 'Install yq and coreutils (macOS)',
        ifExpression: Runner.os.eq(const Expression.literal('macOS')),
        run: r'''
brew install yq coreutils
echo "$(brew --prefix)/opt/coreutils/libexec/gnubin" >> $GITHUB_PATH
''',
      ),
    ],
    ...CheckoutBuilder(withSubmodules: config.withSubmodules).build(),
    ...ProjectPrepareBuilder(config: config).build(),
  ];
}
