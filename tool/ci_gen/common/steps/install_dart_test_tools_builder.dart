import '../../types/step.dart';
import '../api/step_builder.dart';
import '../globals.dart';

class InstallDartTestToolsBuilder implements StepBuilder {
  const InstallDartTestToolsBuilder();

  @override
  Iterable<Step> build() => [
        Step.run(
          name: 'Install dart_test_tools',
          run: 'dart pub global activate '
              'dart_test_tools ^$dartTestToolsVersion',
        ),
      ];
}
