import '../../../common/api/job_config.dart';
import '../../../common/api/step_builder.dart';
import '../../../common/inputs.dart';
import '../../../types/step.dart';
import '../../steps/build_app_builder.dart';

base mixin BuildWebArchiveConfig on JobConfig, BuildAppConfig {
  late final baseHref = inputContext(WorkflowInputs.baseHref);

  @override
  String get buildTarget => 'web';

  @override
  String get buildArgs =>
      '--no-web-resources-cdn '
      '--csp '
      '--source-maps '
      '--dump-info '
      "--base-href='$baseHref'";

  @override
  String get artifactDir => 'build/web-archive';
}

class BuildWebArchiveBuilder implements StepBuilder {
  final BuildWebArchiveConfig config;

  const BuildWebArchiveBuilder({required this.config});

  @override
  Iterable<Step> build() => [
    ...BuildAppBuilder(
      config: config,
      packageSteps: [
        Step.run(
          name: 'Create archive',
          run: r'''
set -eo pipefail

archive_name=$(jq -r '.short_name' ../web/manifest.json)
mkdir web-archive
tar -cJvf "web-archive/$archive_name Web.tar.xz" web
''',
          workingDirectory: '${config.workingDirectory}/build',
        ),
      ],
    ).build(),
  ];
}
