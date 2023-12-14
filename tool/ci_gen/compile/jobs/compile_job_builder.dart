import 'package:freezed_annotation/freezed_annotation.dart';

import '../../common/jobs/sdk_job_builder.dart';
import '../../dart/jobs/dart_sdk_job_builder_mixin.dart';
import '../../types/expression.dart';
import '../../types/id.dart';
import '../../types/job.dart';
import '../../types/matrix.dart';
import '../../types/strategy.dart';
import '../steps/compile_builder.dart';

part 'compile_job_builder.freezed.dart';
part 'compile_job_builder.g.dart';

class _CompileJobMatrix implements ICompileMatrix {
  @override
  final Expression platform;
  @override
  final Expression binaryType;
  @override
  final Expression compileArgs;
  @override
  final Expression archiveType;
  final Expression os;

  const _CompileJobMatrix({
    required this.platform,
    required this.binaryType,
    required this.compileArgs,
    required this.archiveType,
    required this.os,
  });
}

enum _BinaryType {
  exe,
  js,
}

@freezed
class _PlatformInclude with _$PlatformInclude {
  const factory _PlatformInclude({
    required String platform,
    required _BinaryType binaryType,
    // ignore: invalid_annotation_target
    @JsonKey(includeIfNull: false) String? compileArgs,
    required ArchiveType archiveType,
    required String os,
  }) = __PlatformInclude;

  // ignore: unused_element
  factory _PlatformInclude.fromJson(Map<String, dynamic> json) =>
      _$PlatformIncludeFromJson(json);
}

final class CompileJobBuilder extends SdkJobBuilder
    with DartSdkJobBuilderMixin {
  static const _matrix = _CompileJobMatrix(
    platform: Expression('matrix.platform'),
    binaryType: Expression('matrix.binaryType'),
    compileArgs: Expression('matrix.compileArgs'),
    archiveType: Expression('matrix.archiveType'),
    os: Expression('matrix.os'),
  );

  static const _platformIncludes = [
    _PlatformInclude(
      platform: 'linux',
      binaryType: _BinaryType.exe,
      compileArgs:
          r'-S "build/bin/$executableName.sym" -o "build/bin/$executableName"',
      archiveType: ArchiveType.tar,
      os: 'ubuntu-latest',
    ),
    _PlatformInclude(
      platform: 'windows',
      binaryType: _BinaryType.exe,
      compileArgs:
          r'-S "build/bin/$executableName.sym" -o "build/bin/$executableName.exe"',
      archiveType: ArchiveType.zip,
      os: 'windows-latest',
    ),
    _PlatformInclude(
      platform: 'macos',
      binaryType: _BinaryType.exe,
      compileArgs:
          r'-S "build/bin/$executableName.sym" -o "build/bin/$executableName"',
      archiveType: ArchiveType.tar,
      os: 'macos-latest',
    ),
    _PlatformInclude(
      platform: 'web',
      binaryType: _BinaryType.js,
      compileArgs: r'-O2 --server-mode -o "build/bin/$executableName.js"',
      archiveType: ArchiveType.zip,
      os: 'ubuntu-latest',
    ),
  ];

  @override
  JobId get id => const JobId('compile');

  @override
  final Expression dartSdkVersion;
  final Expression workingDirectory;
  final Expression artifactDependencies;
  final Expression buildRunner;
  final Expression buildRunnerArgs;
  final Expression removePubspecOverrides;

  CompileJobBuilder({
    required this.dartSdkVersion,
    required this.workingDirectory,
    required this.artifactDependencies,
    required this.buildRunner,
    required this.buildRunnerArgs,
    required this.removePubspecOverrides,
  });

  @override
  Job build() => Job(
        name: 'Create compiled artifacts',
        permissions: const {
          'contents': 'read',
        },
        strategy: Strategy(
          failFast: false,
          matrix: Matrix(
            {
              'platform': _platformIncludes.map((i) => i.platform).toList(),
            },
            include: _platformIncludes.map((i) => i.toJson()).toList(),
          ),
        ),
        runsOn: _matrix.os.toString(),
        steps: [
          ...buildSetupSdkSteps(),
          ...CompileBuilder(
            workingDirectory: workingDirectory,
            artifactDependencies: artifactDependencies,
            buildRunner: buildRunner,
            buildRunnerArgs: buildRunnerArgs,
            removePubspecOverrides: removePubspecOverrides,
            matrix: _matrix,
            pubTool: pubTool,
            runTool: runTool,
          ).build()
        ],
      );
}
