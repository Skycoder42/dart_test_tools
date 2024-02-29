import '../../common/api/step_builder.dart';
import '../../types/id.dart';
import '../../types/step.dart';

class GenerateBuildNumberBuilder implements StepBuilder {
  static const stepId = StepId('generateBuildNumber');

  @override
  Iterable<Step> build() => [
        Step.run(
          id: stepId,
          name: 'Generate build number',
          run: 'dart run tool/generate_build_number.dart',
        ),
      ];
}
