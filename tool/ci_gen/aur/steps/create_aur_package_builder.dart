import '../../common/api/step_builder.dart';
import '../../types/step.dart';

class CreateAurPackageBuilder implements StepBuilder {
  @override
  Iterable<Step> build() => [
        const Step.run(
          name: 'Generate PKGBUILD from dart package',
          run: 'dart pub global run dart_test_tools:generate_pkgbuild ../aur',
          workingDirectory: 'src',
        ),
      ];
}
