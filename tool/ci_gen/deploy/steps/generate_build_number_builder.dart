import '../../common/api/job_config.dart';
import '../../common/api/step_builder.dart';
import '../../common/api/working_directory_config.dart';
import '../../common/inputs.dart';
import '../../types/id.dart';
import '../../types/step.dart';

base mixin GenerateBuildNumberConfig on JobConfig, WorkingDirectoryConfig {
  late final buildNumberArgs = inputContext(WorkflowInputs.buildNumberArgs);
}

class GenerateBuildNumberBuilder implements StepBuilder {
  static const stepId = StepId('generateBuildNumber');
  static final buildNumberOutput = stepId.output('buildNumber');

  final GenerateBuildNumberConfig config;
  final bool asEnv;

  const GenerateBuildNumberBuilder({required this.config, this.asEnv = false});

  @override
  Iterable<Step> build() => [
    Step.run(
      id: stepId,
      name: 'Generate build number',
      run:
          'dart pub global run dart_test_tools:generate_build_number '
          '${config.buildNumberArgs}${asEnv ? ' --env' : ''}',
      workingDirectory: config.workingDirectory.toString(),
    ),
  ];
}
