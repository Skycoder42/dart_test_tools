import '../../../common/api/step_builder.dart';
import '../../../common/contexts.dart';
import '../../../common/steps/install_dart_test_tools_builder.dart';
import '../../../common/steps/project_setup_builder.dart';
import '../../../common/tools.dart';
import '../../../types/expression.dart';
import '../../../types/step.dart';
import '../../steps/build_app_builder.dart';
import '../../steps/generate_build_number_builder.dart';

class BuildWindowsInstallerBuilder implements StepBuilder {
  final Expression workingDirectory;
  final Expression artifactDependencies;
  final Expression buildRunner;
  final Expression buildRunnerArgs;
  final Expression buildNumberArgs;
  final Expression dartDefines;
  final Expression signingCert;
  final Expression signingCertPassword;
  final String pubTool;
  final String runTool;

  const BuildWindowsInstallerBuilder({
    required this.workingDirectory,
    required this.artifactDependencies,
    required this.buildRunner,
    required this.buildRunnerArgs,
    required this.buildNumberArgs,
    required this.dartDefines,
    required this.signingCert,
    required this.signingCertPassword,
    required this.pubTool,
    required this.runTool,
  });

  @override
  Iterable<Step> build() => [
        ...const InstallDartTestToolsBuilder().build(),
        ...ProjectSetupBuilder(
          workingDirectory: workingDirectory,
          artifactDependencies: artifactDependencies,
          buildRunner: buildRunner,
          buildRunnerArgs: buildRunnerArgs,
          releaseMode: true,
          pubTool: pubTool,
          runTool: runTool,
        ).build(),
        ...GenerateBuildNumberBuilder(
          buildNumberArgs: buildNumberArgs,
          workingDirectory: workingDirectory,
        ).build(),
        ...BuildAppBuilder(
          buildNumber: GenerateBuildNumberBuilder.buildNumberOutput.expression,
          workingDirectory: workingDirectory,
          dartDefines: dartDefines,
          buildTarget: 'windows',
          debugInfoDir: 'build/windows/msix',
        ).build(),
        Step.run(
          name: 'Prepare signing certificate',
          run: "echo '$signingCert' | "
              "openssl base64 -d -out '${Runner.temp}/signing-cert.pfx'",
        ),
        Step.run(
          name: 'Create msix package',
          run: 'dart run msix:create --release '
              '--build-windows false '
              r'--output-path build\windows\msix '
              "--certificate-path '${Runner.temp}\\signing-cert.pfx' "
              "--certificate-password '$signingCertPassword' "
              '--install-certificate false',
          workingDirectory: workingDirectory.toString(),
        ),
        Step.run(
          name: 'Cleanup signing certificate',
          ifExpression: Functions.always,
          continueOnError: true,
          run: "Remove-Item -Force '${Runner.temp}/signing-cert.pfx'",
        ),
        Step.uses(
          name: 'Upload msix installer and debug info',
          uses: Tools.actionsUploadArtifact,
          withArgs: {
            'name': 'windows-installer',
            'path': '$workingDirectory/build/windows/msix',
            'retention-days': 1,
            'if-no-files-found': 'error',
          },
        ),
      ];
}
