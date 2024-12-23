import '../../common/api/job_config.dart';
import '../../common/api/step_builder.dart';
import '../../common/tools.dart';
import '../../types/expression.dart';
import '../../types/step.dart';

base mixin MakedebConfig on JobConfig {
  late Expression workingDirectory;
}

class MakedebBuilder implements StepBuilder {
  final MakedebConfig config;

  const MakedebBuilder({
    required this.config,
  });

  @override
  Iterable<Step> build() => [
        const Step.run(
          name: 'Create deb dir',
          run: 'mkdir deb',
        ),
        Step.run(
          name: 'Generate PKGBUILD from dart package',
          run: 'dart pub global run dart_test_tools:generate_pkgbuild '
              '--input src/${config.workingDirectory} --output deb --makedeb',
        ),
        const Step.run(
          name: 'Update source checksums',
          run: 'makedeb --gen-integ >> PKGBUILD',
          workingDirectory: 'deb',
        ),
        const Step.run(
          name: 'Lint PKGBUILD',
          run: 'makedeb --lint',
          workingDirectory: 'deb',
        ),
        const Step.run(
          name: 'Build debian package',
          run: 'makedeb -s --no-confirm',
          workingDirectory: 'deb',
        ),
        const Step.uses(
          name: 'Upload debian package to artifacts',
          uses: Tools.actionsUploadArtifact,
          withArgs: <String, dynamic>{
            'name': 'debian-package',
            'path': 'deb/*.deb',
            'retention-days': 3,
            'if-no-files-found': 'error',
          },
        ),
      ];
}
