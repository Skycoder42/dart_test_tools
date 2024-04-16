import '../../common/api/step_builder.dart';
import '../../types/expression.dart';
import '../../types/id.dart';
import '../../types/step.dart';

class GenerateBuildNumberBuilder implements StepBuilder {
  static const stepId = StepId('generateBuildNumber');
  static final buildNumberOutput = stepId.output('buildNumber');

  final Expression buildNumberArgs;
  final Expression workingDirectory;
  final bool asEnv;

  const GenerateBuildNumberBuilder({
    required this.buildNumberArgs,
    required this.workingDirectory,
    this.asEnv = false,
  });

  @override
  Iterable<Step> build() => [
        Step.run(
          id: stepId,
          name: 'Generate build number',
          run: 'dart pub global run dart_test_tools:generate_build_number '
              '$buildNumberArgs${asEnv ? ' --env' : ''}',
          workingDirectory: workingDirectory.toString(),
        ),
      ];
}
