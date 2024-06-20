import '../../common/api/step_builder.dart';
import '../../common/contexts.dart';
import '../../types/expression.dart';
import '../../types/step.dart';

class FlutterBuildBuilder implements StepBuilder {
  static final _dartDefinesPath = '${Runner.temp}/dart-defines.env';

  final Expression buildNumber;
  final Expression workingDirectory;
  final Expression dartDefines;
  final String buildTarget;
  final String? buildArgs;
  final List<Step> preBuildSteps;
  final List<String> cleanupPaths;

  const FlutterBuildBuilder({
    required this.buildNumber,
    required this.workingDirectory,
    required this.dartDefines,
    required this.buildTarget,
    this.buildArgs,
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
        run: "echo '$dartDefines' > '$_dartDefinesPath'",
        shell: 'bash',
      ),
      ...preBuildSteps,
      Step.run(
        name: 'Build $buildTarget',
        run: 'flutter build $buildTarget '
            '--release '
            '--build-number=$buildNumber '
            "--dart-define-from-file='$_dartDefinesPath'"
            '${buildArgs != null ? ' $buildArgs' : ''}',
        workingDirectory: workingDirectory.toString(),
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
