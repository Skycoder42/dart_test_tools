import '../../common/api/step_builder.dart';
import '../../types/step.dart';

class MakedebBuilder implements StepBuilder {
  @override
  Iterable<Step> build() => const [
        Step.run(
          name: 'Create deb dir',
          run: 'mkdir deb',
        ),
        Step.run(
          name: 'Generate PKGBUILD from dart package',
          run: 'dart pub global run dart_test_tools:generate_pkgbuild '
              '--input src --output deb --makedeb',
        ),
        Step.run(
          name: 'Update source checksums',
          run: 'makedeb --gen-integ >> PKGBUILD',
          workingDirectory: 'deb',
        ),
        Step.run(
          name: 'Lint PKGBUILD',
          run: 'makedeb --lint',
          workingDirectory: 'deb',
        ),
        Step.run(
          name: 'Build debian package',
          run: 'makedeb -s --no-confirm',
          workingDirectory: 'deb',
        ),
      ];
}
