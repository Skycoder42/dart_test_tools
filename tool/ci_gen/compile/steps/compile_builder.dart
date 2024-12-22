import '../../common/api/matrix_job_builder_mixin.dart';
import '../../common/api/platform_matrix_job_builder_mixin.dart';
import '../../common/api/step_builder.dart';
import '../../common/steps/project_setup_builder.dart';
import '../../common/tools.dart';
import '../../dart/dart_platform.dart';
import '../../types/expression.dart';
import '../../types/step.dart';

enum BinaryType {
  exe,
  js;

  String toJson() => name;
}

enum ArchiveType {
  tar,
  zip;

  Expression get expression => Expression.literal(name);

  String toJson() => name;
}

final class BinaryTypeMatrixProperty extends IMatrixProperty<DartPlatform> {
  const BinaryTypeMatrixProperty();

  @override
  String get name => 'binaryType';

  @override
  Object? valueFor(DartPlatform selector) => switch (selector) {
        DartPlatform(isWeb: true) => BinaryType.js,
        _ => BinaryType.exe,
      };
}

final class CompileArgsMatrixProperty extends IMatrixProperty<DartPlatform> {
  const CompileArgsMatrixProperty();

  @override
  String get name => 'compileArgs';

  @override
  Object? valueFor(DartPlatform selector) => switch (selector) {
        DartPlatform.linux ||
        DartPlatform.macos =>
          r'-S "build/bin/$executableName.sym" -o "build/bin/$executableName"',
        DartPlatform.windows =>
          r'-S "build/bin/$executableName.sym" -o "build/bin/$executableName.exe"',
        DartPlatform.web =>
          r'-O2 --server-mode -o "build/bin/$executableName.js"',
      };
}

final class ArchiveTypeMatrixProperty extends IMatrixProperty<DartPlatform> {
  const ArchiveTypeMatrixProperty();

  @override
  String get name => 'archiveType';

  @override
  Object? valueFor(DartPlatform selector) => switch (selector) {
        DartPlatform.windows || DartPlatform.web => ArchiveType.zip,
        _ => ArchiveType.tar,
      };
}

abstract interface class ICompileMatrix {
  Expression get platform;
  Expression get binaryType;
  Expression get compileArgs;
  Expression get archiveType;
}

class CompileBuilder implements StepBuilder {
  final Expression workingDirectory;
  final Expression artifactDependencies;
  final Expression buildRunner;
  final Expression buildRunnerArgs;
  final Expression removePubspecOverrides;
  final Expression localResolution;
  final Expression archivePrefix;
  final PlatformMatrixProperty platform;
  final BinaryTypeMatrixProperty binaryType;
  final CompileArgsMatrixProperty compileArgs;
  final ArchiveTypeMatrixProperty archiveType;
  final String pubTool;
  final String runTool;

  CompileBuilder({
    required this.workingDirectory,
    required this.artifactDependencies,
    required this.buildRunner,
    required this.buildRunnerArgs,
    required this.removePubspecOverrides,
    required this.localResolution,
    required this.archivePrefix,
    required this.platform,
    required this.binaryType,
    required this.compileArgs,
    required this.archiveType,
    required this.pubTool,
    required this.runTool,
  });

  @override
  Iterable<Step> build() => [
        ...ProjectSetupBuilder(
          workingDirectory: workingDirectory,
          artifactDependencies: artifactDependencies,
          buildRunner: buildRunner,
          buildRunnerArgs: buildRunnerArgs,
          removePubspecOverrides:
              ExpressionOrValue.expression(removePubspecOverrides),
          localResolution: ExpressionOrValue.expression(localResolution),
          releaseMode: true,
          isFlutter: const ExpressionOrValue.value(false),
          pubTool: pubTool,
          runTool: runTool,
        ).build(),
        Step.run(
          name: 'Compile executables',
          run: '''
set -eo pipefail
mkdir -p build/bin
yq ".executables.[] | key" pubspec.yaml | while read executableName; do
  dartScript=\$(yq ".executables.[\\"\$executableName\\"] // \\"\$executableName\\"" pubspec.yaml)
  dart compile ${binaryType.expression} ${compileArgs.expression} "bin/\$dartScript.dart"
done
''',
          workingDirectory: workingDirectory.toString(),
          shell: 'bash',
        ),
        Step.run(
          name: 'Create release archives (${ArchiveType.tar.name})',
          ifExpression: archiveType.expression.eq(ArchiveType.tar.expression),
          run: '''
set -eo pipefail
shopt -s extglob
mkdir -p ../artifacts
tar -cavf '../artifacts/$archivePrefix-${platform.expression}.tar.xz' !(*.*)
tar -cavf '../artifacts/$archivePrefix-${platform.expression}-debug-symbols.tar.xz' *.sym
''',
          workingDirectory: '$workingDirectory/build/bin',
          shell: 'bash',
        ),
        Step.run(
          name: 'Create release archives (${ArchiveType.zip.name})',
          ifExpression: archiveType.expression.eq(ArchiveType.zip.expression),
          run: '''
set -eo pipefail
shopt -s nullglob
mkdir -p ../artifacts
7z a -y '../artifacts/$archivePrefix-${platform.expression}.zip' *.exe *.js
7z a -y '../artifacts/$archivePrefix-${platform.expression}-debug-symbols.zip' *.sym *.js.*
''',
          workingDirectory: '$workingDirectory/build/bin',
          shell: 'bash',
        ),
        Step.uses(
          name: 'Upload compiled binaries artifact',
          uses: Tools.actionsUploadArtifact,
          withArgs: <String, dynamic>{
            'name': '$archivePrefix-${platform.expression}',
            'path': '$workingDirectory/build/artifacts/*',
            'retention-days': 3,
            'if-no-files-found': 'error',
          },
        ),
      ];
}
