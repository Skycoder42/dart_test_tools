import '../../common/api/job_config.dart';
import '../../common/api/matrix_job_builder_mixin.dart';
import '../../common/api/platform_matrix_job_builder_mixin.dart';
import '../../common/api/step_builder.dart';
import '../../common/inputs.dart';
import '../../common/steps/project_setup_builder.dart';
import '../../common/tools.dart';
import '../../dart/dart_platform.dart';
import '../../types/expression.dart';
import '../../types/id.dart';
import '../../types/step.dart';

enum ArchiveType {
  tar,
  zip;

  Expression get expression => Expression.literal(name);

  String toJson() => name;
}

base mixin CompileConfig on JobConfig, ProjectSetupConfig {
  late final archivePrefix = inputContext(WorkflowInputs.archivePrefix);

  @override
  late final withSubmodules = inputContext(WorkflowInputs.withSubmodules);

  @override
  bool get releaseMode => true;
}

final class ExecutableSuffixProperty extends IMatrixProperty<DartPlatform> {
  const ExecutableSuffixProperty();

  @override
  String get name => 'executableSuffix';

  @override
  String valueFor(DartPlatform selector) => switch (selector) {
    .windows => '.exe',
    _ => '',
  };
}

final class ArchiveTypeMatrixProperty extends IMatrixProperty<DartPlatform> {
  const ArchiveTypeMatrixProperty();

  @override
  String get name => 'archiveType';

  @override
  ArchiveType valueFor(DartPlatform selector) => switch (selector) {
    .windows || .web => .zip,
    _ => .tar,
  };
}

class CompileBuilder implements StepBuilder {
  static const detectArchiveNameId = StepId('detect-archive-name');
  static final archiveNameOutput = detectArchiveNameId.output('archive-name');

  final CompileConfig config;
  final PlatformMatrixProperty platform;
  final ExecutableSuffixProperty executableSuffix;
  final ArchiveTypeMatrixProperty archiveType;

  CompileBuilder({
    required this.config,
    required this.platform,
    required this.executableSuffix,
    required this.archiveType,
  });

  @override
  Iterable<Step> build() => [
    ...ProjectSetupBuilder(config: config).build(),
    Step.run(
      id: detectArchiveNameId,
      name: 'Detect archive name',
      ifExpression: config.archivePrefix.eq(.empty),
      run:
          '''
set -euo pipefail
package_name=\$(yq -r .name pubspec.yaml)
package_version=\$(yq -r .version pubspec.yaml)
${archiveNameOutput.bashSetter(r'$package_name-$package_version')}
''',
      workingDirectory: config.workingDirectory.toString(),
      shell: 'bash',
    ),
    Step.run(
      name: 'Compile executables',
      run:
          '''
set -euo pipefail
yq ".executables.[] | key" pubspec.yaml | while read executableName; do
  echo "::group::Compiling \$executableName"
  dartScript=\$(yq ".executables.[\\"\$executableName\\"] // \\"\$executableName\\"" pubspec.yaml)
  dart build cli -t "bin/\$dartScript.dart" -o build/cli
  if [[ "\$executableName" != "\$dartScript" ]]; then
    echo ">> Renaming \$dartScript to \$executableName"
    mv \\
      "build/cli/bundle/bin/\$dartScript${executableSuffix.expression}" \\
      "build/cli/bundle/bin/\$executableName${executableSuffix.expression}"
  fi
  echo "::endgroup::"
done
echo '>> Renaming bundle directory to ${config.archivePrefix | archiveNameOutput.expression}'
mv build/cli/bundle 'build/cli/${config.archivePrefix | archiveNameOutput.expression}'
''',
      workingDirectory: config.workingDirectory.toString(),
      shell: 'bash',
    ),
    Step.run(
      name: 'Create release archive (${ArchiveType.tar.name})',
      ifExpression: archiveType.expression.eq(ArchiveType.tar.expression),
      run:
          '''
set -euo pipefail
mkdir -p ../artifacts
tar -cavf '../artifacts/${config.archivePrefix | archiveNameOutput.expression}-${platform.expression}.tar.xz' .
''',
      workingDirectory: '${config.workingDirectory}/build/cli',
      shell: 'bash',
    ),
    Step.run(
      name: 'Create release archive (${ArchiveType.zip.name})',
      ifExpression: archiveType.expression.eq(ArchiveType.zip.expression),
      run:
          '''
set -eo pipefail
mkdir -p ../artifacts
7z a -y '../artifacts/${config.archivePrefix | archiveNameOutput.expression}-${platform.expression}.zip' .
''',
      workingDirectory: '${config.workingDirectory}/build/cli',
      shell: 'bash',
    ),
    Step.uses(
      name: 'Upload compiled binaries artifact',
      uses: Tools.actionsUploadArtifact,
      withArgs: <String, dynamic>{
        'name': '${config.archivePrefix}-${platform.expression}',
        'path': '${config.workingDirectory}/build/artifacts/*',
        'retention-days': 3,
        'if-no-files-found': 'error',
      },
    ),
  ];
}
