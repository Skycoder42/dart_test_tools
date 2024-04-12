import '../../../common/api/step_builder.dart';
import '../../../common/contexts.dart';
import '../../../types/expression.dart';
import '../../../types/step.dart';

class BuildAppBuilder implements StepBuilder {
  final Expression buildNumber;
  final Expression workingDirectory;
  final Expression dartDefines;
  final String buildTarget;
  final String debugInfoDir;

  const BuildAppBuilder({
    required this.buildNumber,
    required this.workingDirectory,
    required this.dartDefines,
    required this.buildTarget,
    required this.debugInfoDir,
  });

  @override
  Iterable<Step> build() => [
        Step.run(
          name: 'Prepare dart defines',
          run: "echo '$dartDefines' > '${Runner.temp}/dart-defines.env'",
          shell: 'bash',
        ),
        Step.run(
          name: 'Build android appbundle',
          run: 'flutter build $buildTarget '
              '--release '
              '--build-number=$buildNumber '
              '--obfuscate --split-debug-info=$debugInfoDir/debug-info '
              "--dart-define-from-file='${Runner.temp}/dart-defines.env'",
          workingDirectory: workingDirectory.toString(),
        ),
        Step.run(
          name: 'Cleanup dart defines',
          ifExpression: Expression.always,
          continueOnError: true,
          run: "rm -f '${Runner.temp}/dart-defines.env'",
          shell: 'bash',
        ),
      ];
}
