import '../../common/api/step_builder.dart';
import '../../types/step.dart';

class CreateAurPackageBuilder implements StepBuilder {
  const CreateAurPackageBuilder();

  @override
  Iterable<Step> build() => [
        const Step.run(
          name: 'Generate PKGBUILD from dart package',
          run: 'dart pub global run '
              'dart_test_tools:generate_pkgbuild --input src --output aur',
        ),
        const Step.run(
          name: 'Change ownership of AUR repo to the build user',
          run: 'chown -R build:build aur',
        ),
        _suRun(
          name: 'Update source checksums',
          run: 'updpkgsums',
        ),
        _suRun(
          name: 'Run namcap linter',
          run: 'namcap -i PKGBUILD',
        ),
        _suRun(
          name: 'Test if package can be build',
          run: 'makepkg -sfC --check --noconfirm',
        ),
        _suRun(
          name: 'Generate SRCINFO',
          run: 'makepkg --printsrcinfo > .SRCINFO',
        ),
        const Step.run(
          name: 'Change ownership of AUR repo back to the root user',
          run: 'chown -R root:root aur',
        ),
      ];

  Step _suRun({
    required String name,
    required String run,
  }) =>
      Step.run(
        name: name,
        run: "su build -c '$run'",
        workingDirectory: 'aur',
      );
}
