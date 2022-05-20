import 'package:freezed_annotation/freezed_annotation.dart';

import '../../common/api/expression_builder.dart';
import '../../common/builders/sdk_job_builder.dart';
import '../../dart/builders/dart_sdk_job_builder_mixin.dart';
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
  final Expression os;

  const _CompileJobMatrix({
    required this.platform,
    required this.binaryType,
    required this.compileArgs,
    required this.os,
  });
}

enum _BinaryType {
  exe,
  js,
}

@freezed
class _PlatformInclude with _$_PlatformInclude {
  const factory _PlatformInclude({
    required String platform,
    required _BinaryType binaryType,
    // ignore: invalid_annotation_target
    @JsonKey(includeIfNull: false) String? compileArgs,
    required String os,
  }) = __PlatformInclude;

  // ignore: unused_element
  factory _PlatformInclude.fromJson(Map<String, dynamic> json) =>
      _$_PlatformIncludeFromJson(json);
}

class CompileJobBuilder extends SdkJobBuilder with DartSdkJobBuilderMixin {
  static const _matrix = _CompileJobMatrix(
    platform: Expression('matrix.platform'),
    binaryType: Expression('matrix.binaryType'),
    compileArgs: Expression('matrix.compileArgs'),
    os: Expression('matrix.os'),
  );

  static const _platformIncludes = [
    _PlatformInclude(
      platform: 'linux',
      binaryType: _BinaryType.exe,
      compileArgs: r'-S "bin/$target.exe.sym"',
      os: 'ubuntu-latest',
    ),
    _PlatformInclude(
      platform: 'windows',
      binaryType: _BinaryType.exe,
      compileArgs: r'-S "bin/$target.exe.sym"',
      os: 'windows-latest',
    ),
    _PlatformInclude(
      platform: 'macos',
      binaryType: _BinaryType.exe,
      compileArgs: r'-S "bin/$target.exe.sym"',
      os: 'macos-latest',
    ),
    _PlatformInclude(
      platform: 'web',
      binaryType: _BinaryType.js,
      compileArgs: r'-m -o "bin/$target.js"',
      os: 'ubuntu-latest',
    ),
  ];

  @override
  JobId get id => const JobId('compile');

  final Expression platforms;
  final Expression targets;
  @override
  final Expression dartSdkVersion;
  final Expression repository;
  final Expression workingDirectory;
  final Expression buildRunner;

  CompileJobBuilder({
    required this.targets,
    required this.dartSdkVersion,
    required this.repository,
    required this.workingDirectory,
    required this.buildRunner,
    required ExpressionBuilderFn<List<String>> platforms,
  }) : platforms = platforms(_platformIncludes.map((i) => i.platform).toList());

  @override
  Job build() => Job(
        name: 'Create compiled artifacts',
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
            repository: repository,
            workingDirectory: workingDirectory,
            buildRunner: buildRunner,
            targets: targets,
            matrix: _matrix,
            pubTool: pubTool,
            runTool: runTool,
          ).build()
        ],
      );
}
