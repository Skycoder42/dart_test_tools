import '../../../common/api/step_builder.dart';
import '../../../types/expression.dart';
import '../../../types/step.dart';
import '../../steps/build_app_builder.dart';

class BuildWebArchiveBuilder implements StepBuilder {
  final Expression workingDirectory;
  final Expression artifactDependencies;
  final Expression buildRunner;
  final Expression buildRunnerArgs;
  final Expression buildNumberArgs;
  final Expression baseHref;
  final Expression dartDefines;
  final String pubTool;
  final String runTool;

  const BuildWebArchiveBuilder({
    required this.workingDirectory,
    required this.artifactDependencies,
    required this.buildRunner,
    required this.buildRunnerArgs,
    required this.buildNumberArgs,
    required this.dartDefines,
    required this.baseHref,
    required this.pubTool,
    required this.runTool,
  });

  @override
  Iterable<Step> build() => [
        ...BuildAppBuilder(
          workingDirectory: workingDirectory,
          artifactDependencies: artifactDependencies,
          buildRunner: buildRunner,
          buildRunnerArgs: buildRunnerArgs,
          buildNumberArgs: buildNumberArgs,
          dartDefines: dartDefines,
          pubTool: pubTool,
          runTool: runTool,
          buildTarget: 'web',
          buildArgs: '--no-web-resources-cdn '
              '--csp '
              '--source-maps '
              '--dump-info '
              "--base-href='$baseHref'",
          artifactDir: 'build/web-archive',
          packageSteps: [
            Step.run(
              name: 'Create archive',
              run: r'''
set -eo pipefail

archive_name=$(jq -r '.short_name' ../web/manifest.json)
mkdir web-archive
tar -cJvf "web-archive/$archive_name Web.tar.xz" web
''',
              workingDirectory: '$workingDirectory/build',
            ),
          ],
        ).build(),
      ];
}
