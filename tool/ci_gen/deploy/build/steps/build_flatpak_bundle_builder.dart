import '../../../common/api/matrix_job_builder_mixin.dart';
import '../../../common/api/step_builder.dart';
import '../../../common/contexts.dart';
import '../../../common/steps/checkout_builder.dart';
import '../../../common/tools.dart';
import '../../../types/expression.dart';
import '../../../types/step.dart';

enum FlatpakArchMatrixSelector implements IMatrixSelector {
  x86_64,
  aarch64;
}

final class ArchMatrixProperty
    extends IMatrixProperty<FlatpakArchMatrixSelector> {
  const ArchMatrixProperty();
  @override
  String get name => 'arch';

  @override
  Object? valueFor(FlatpakArchMatrixSelector include) => include.name;
}

final class QEmuArchProperty
    extends IMatrixProperty<FlatpakArchMatrixSelector> {
  const QEmuArchProperty();

  @override
  String get name => 'qemuArch';

  @override
  Object? valueFor(FlatpakArchMatrixSelector include) =>
      include == FlatpakArchMatrixSelector.aarch64 ? 'arm64' : null;
}

class BuildFlatpakBundleBuilder implements StepBuilder {
  final Expression sdkVersion;
  final Expression bundleName;
  final Expression workingDirectory;
  final Expression artifactDependencies;
  final Expression manifestPath;
  final Expression gpgKeyId;
  final Expression gpgKey;
  final ArchMatrixProperty arch;
  final QEmuArchProperty qemuArch;

  const BuildFlatpakBundleBuilder({
    required this.sdkVersion,
    required this.bundleName,
    required this.workingDirectory,
    required this.artifactDependencies,
    required this.manifestPath,
    required this.gpgKeyId,
    required this.gpgKey,
    required this.arch,
    required this.qemuArch,
  });

  @override
  Iterable<Step> build() => [
        Step.run(
          name: 'Install docker',
          ifExpression: qemuArch.expression,
          run: 'dnf -y install docker',
        ),
        Step.uses(
          name: 'Setup QEMU',
          ifExpression: qemuArch.expression,
          uses: Tools.dockerSetupQemuAction,
          withArgs: {
            'platforms': qemuArch.expression.toString(),
          },
        ),
        Step.run(
          name: 'Download flatpak flutter SDK',
          run: "curl --fail-with-body -L -o /tmp/flutter.flatpak "
              "'https://github.com/Skycoder42/dart_test_tools/releases/download/flatpak-flutter-extension%2F$sdkVersion/org.freedesktop.Sdk.Extension.flutter_${sdkVersion}_${arch.expression}.flatpak'",
        ),
        Step.run(
          name: 'Install flatpak flutter SDK',
          run: 'flatpak install --system -y --noninteractive '
              '/tmp/flutter.flatpak',
        ),
        ...CheckoutBuilder(
          artifactDependencies: artifactDependencies,
          artifactTargetDir: Github.workspace,
        ).build(),
        Step.run(
          name: 'Import GPG key',
          run: "echo '$gpgKey' | gpg --import",
        ),
        Step.uses(
          name: 'Build flatpak bundle',
          uses: Tools.bilelmoussaouiFlatpakGithubActionsFlatpakBuilder,
          withArgs: {
            'bundle': bundleName.toString(),
            'manifest-path': '$workingDirectory/$manifestPath',
            'branch': Github.refName.toString(),
            'gpg-sign': gpgKeyId.toString(),
            'cache': false,
            'arch': arch.expression.toString(),
          },
        ),
        Step.run(
          name: 'Delete GPG key',
          ifExpression: Expression('always()'), // TODO extract
          continueOnError: true,
          run: "gpg --batch --yes --delete-secret-keys '$gpgKeyId'",
        ),
      ];
}
