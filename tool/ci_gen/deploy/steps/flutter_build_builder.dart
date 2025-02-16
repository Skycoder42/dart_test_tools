import '../../common/api/job_config.dart';
import '../../common/api/step_builder.dart';
import '../../common/api/working_directory_config.dart';
import '../../common/contexts.dart';
import '../../common/secrets.dart';
import '../../types/expression.dart';
import '../../types/step.dart';

base mixin FlutterBuildConfig on JobConfig, WorkingDirectoryConfig {
  late final dartDefines = secretContext(WorkflowSecrets.dartDefines);
  String get buildTarget;
  String? get buildArgs => null;
}

class FlutterBuildBuilder implements StepBuilder {
  static final _dartDefinesPath = '${Runner.temp}/dart-defines.env';

  final Expression buildNumber;
  final FlutterBuildConfig config;
  final List<Step> preBuildSteps;
  final List<String> cleanupPaths;

  const FlutterBuildBuilder({
    required this.buildNumber,
    required this.config,
    this.preBuildSteps = const [],
    this.cleanupPaths = const [],
  });

  @override
  Iterable<Step> build() {
    final allCleanups = [_dartDefinesPath, ...cleanupPaths];
    final cleanupScript = StringBuffer();
    for (final cleanupFile in allCleanups) {
      cleanupScript.writeln("rm -rfv '$cleanupFile'");
    }

    return [
      Step.run(
        name: 'Prepare dart defines',
        run: "echo '${config.dartDefines}' > '$_dartDefinesPath'",
        shell: 'bash',
      ),
      ...preBuildSteps,
      Step.run(
        name: 'Build ${config.buildTarget}',
        run:
            'flutter build ${config.buildTarget} '
            '--release '
            '--build-number=$buildNumber '
            "--dart-define-from-file='$_dartDefinesPath'"
            '${config.buildArgs != null ? ' ${config.buildArgs}' : ''}',
        workingDirectory: config.workingDirectory.toString(),
      ),
      Step.run(
        name: 'Cleanup secure files',
        ifExpression: Functions.always,
        continueOnError: true,
        run: cleanupScript.toString(),
        shell: 'bash',
      ),
    ];
  }
}
