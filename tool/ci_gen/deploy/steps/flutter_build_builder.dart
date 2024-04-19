import '../../common/api/step_builder.dart';
import '../../common/contexts.dart';
import '../../types/expression.dart';
import '../../types/step.dart';

class FlutterBuildBuilder implements StepBuilder {
  final Expression buildNumber;
  final Expression workingDirectory;
  final Expression dartDefines;
  final String buildTarget;

  const FlutterBuildBuilder({
    required this.buildNumber,
    required this.workingDirectory,
    required this.dartDefines,
    required this.buildTarget,
  });

  @override
  Iterable<Step> build() => [
        Step.run(
          name: 'Prepare dart defines',
          run: "echo '$dartDefines' > '${Runner.temp}/dart-defines.env'",
          shell: 'bash',
        ),
        Step.run(
          name: 'Build $buildTarget',
          run: 'flutter build $buildTarget '
              '--release '
              '--build-number=$buildNumber '
              "--dart-define-from-file='${Runner.temp}/dart-defines.env'",
          workingDirectory: workingDirectory.toString(),
        ),
        Step.run(
          name: 'Cleanup dart defines',
          ifExpression: Functions.always,
          continueOnError: true,
          run: "rm -f '${Runner.temp}/dart-defines.env'",
          shell: 'bash',
        ),
      ];
}
