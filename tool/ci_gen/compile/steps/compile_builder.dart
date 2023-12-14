import '../../common/api/step_builder.dart';
import '../../common/steps/platforms_builder_mixin.dart';
import '../../common/steps/project_setup_builder.dart';
import '../../common/tools.dart';
import '../../types/expression.dart';
import '../../types/step.dart';

enum ArchiveType {
  tar,
  zip;

  Expression get expression => Expression.literal(name);
}

abstract interface class ICompileMatrix {
  Expression get platform;
  Expression get binaryType;
  Expression get compileArgs;
  Expression get archiveType;
}

class CompileBuilder with PlatformsBuilderMixin implements StepBuilder {
  final Expression workingDirectory;
  final Expression artifactDependencies;
  final Expression buildRunner;
  final Expression buildRunnerArgs;
  final Expression removePubspecOverrides;
  final ICompileMatrix matrix;
  final String pubTool;
  final String runTool;

  CompileBuilder({
    required this.workingDirectory,
    required this.artifactDependencies,
    required this.buildRunner,
    required this.buildRunnerArgs,
    required this.removePubspecOverrides,
    required this.matrix,
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
          removePubspecOverrides: removePubspecOverrides,
          releaseMode: true,
          pubTool: pubTool,
          runTool: runTool,
          withPlatform: matrix.platform,
        ).build(),
        Step.run(
          name: 'Compile executables',
          ifExpression: shouldRunExpression,
          run: '''
set -eo pipefail
mkdir -p build/bin
yq ".executables.[] | key" pubspec.yaml | while read executableName; do
  dartScript=\$(yq ".executables.[\\"\$executableName\\"] // \\"\$executableName\\"" pubspec.yaml)
  dart compile ${matrix.binaryType} ${matrix.compileArgs} "bin/\$dartScript.dart"
done
''',
          workingDirectory: workingDirectory.toString(),
          shell: 'bash',
        ),
        Step.run(
          name: 'Create release archives (${ArchiveType.tar.name})',
          ifExpression: matrix.archiveType.eq(ArchiveType.tar.expression) &
              shouldRunExpression,
          run: '''
set -eo pipefail
shopt -s extglob
mkdir -p ../artifacts
tar -cavf '../artifacts/binaries-${matrix.platform}.tar.xz' !(*.*)
tar -cavf '../artifacts/binaries-${matrix.platform}-debug-symbols.tar.xz' *.sym
''',
          workingDirectory: '$workingDirectory/build/bin',
          shell: 'bash',
        ),
        Step.run(
          name: 'Create release archives (${ArchiveType.zip.name})',
          ifExpression: matrix.archiveType.eq(ArchiveType.zip.expression) &
              shouldRunExpression,
          run: '''
set -eo pipefail
shopt -s nullglob
mkdir -p ../artifacts
7z a -y '../artifacts/binaries-${matrix.platform}.zip' *.exe *.js
7z a -y '../artifacts/binaries-${matrix.platform}-debug-symbols.zip' *.sym *.js.*
''',
          workingDirectory: '$workingDirectory/build/bin',
          shell: 'bash',
        ),
        Step.uses(
          name: 'Upload compiled binaries artifact',
          ifExpression: shouldRunExpression,
          uses: Tools.actionsUploadArtifact,
          withArgs: <String, dynamic>{
            'name': 'binaries-${matrix.platform}',
            'path': '$workingDirectory/build/artifacts/*',
            'retention-days': 3,
            'if-no-files-found': 'error',
          },
        ),
      ];
}
