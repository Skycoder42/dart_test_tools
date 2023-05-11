import 'package:freezed_annotation/freezed_annotation.dart';

import '../../types/expression.dart';
import '../../types/id.dart';
import '../../types/job.dart';
import '../../types/matrix.dart';
import '../../types/strategy.dart';
import '../steps/unit_test_builder.dart';
import 'sdk_job_builder.dart';

part 'unit_test_job_builder.freezed.dart';
part 'unit_test_job_builder.g.dart';

class _UnitTestJobMatrix implements IUnitTextMatrix {
  @override
  final Expression platform;
  final Expression os;
  @override
  final Expression lcovCleanCommand;
  @override
  final Expression dartTestArgs;

  const _UnitTestJobMatrix({
    required this.platform,
    required this.os,
    required this.lcovCleanCommand,
    required this.dartTestArgs,
  });
}

@freezed
class _PlatformInclude with _$_PlatformInclude {
  const factory _PlatformInclude({
    required String platform,
    required String os,
    required String lcovCleanCommand,
    // ignore: invalid_annotation_target
    @JsonKey(includeIfNull: false) String? dartTestArgs,
  }) = __PlatformInclude;

  // ignore: unused_element
  factory _PlatformInclude.fromJson(Map<String, dynamic> json) =>
      _$_PlatformIncludeFromJson(json);
}

abstract base class UnitTestJobBuilder extends SdkJobBuilder {
  static const _matrix = _UnitTestJobMatrix(
    platform: Expression('matrix.platform'),
    os: Expression('matrix.os'),
    lcovCleanCommand: Expression('matrix.lcovCleanCommand'),
    dartTestArgs: Expression('matrix.dartTestArgs'),
  );

  static const _platformIncludes = [
    _PlatformInclude(
      platform: 'linux',
      os: 'ubuntu-latest',
      lcovCleanCommand: r'sed -i "s#SF:$PWD/#SF:#g" coverage/lcov.info',
    ),
    _PlatformInclude(
      platform: 'windows',
      os: 'windows-latest',
      lcovCleanCommand:
          r'(Get-Content coverage\lcov.info).replace("SF:$PWD\", "SF:").replace("\", "/") | Set-Content coverage\lcov.info',
    ),
    _PlatformInclude(
      platform: 'macos',
      os: 'macos-latest',
      lcovCleanCommand: r'sed -i "" "s#SF:$PWD/#SF:#g" coverage/lcov.info',
    ),
    _PlatformInclude(
      platform: 'web',
      os: 'ubuntu-latest',
      lcovCleanCommand: r'sed -i "s#SF:$PWD/#SF:#g" coverage/lcov.info',
      dartTestArgs: '-p chrome',
    ),
  ];

  final JobId analyzeJobId;
  final Expression workingDirectory;
  final Expression buildRunner;
  final Expression buildRunnerArgs;
  final Expression unitTestPaths;
  final Expression minCoverage;

  UnitTestJobBuilder({
    required this.analyzeJobId,
    required this.workingDirectory,
    required this.buildRunner,
    required this.buildRunnerArgs,
    required this.unitTestPaths,
    required this.minCoverage,
  });

  @override
  JobId get id => const JobId('unit_tests');

  @protected
  String get coverageArgs;

  @protected
  bool get needsFormatting;

  @override
  Job build() => Job(
        name: 'Unit tests',
        ifExpression: unitTestPaths.ne(Expression.empty),
        needs: {analyzeJobId},
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
          ...UnitTestBuilder(
            workingDirectory: workingDirectory,
            buildRunner: buildRunner,
            buildRunnerArgs: buildRunnerArgs,
            unitTestPaths: unitTestPaths,
            minCoverage: minCoverage,
            baseTool: baseTool,
            pubTool: pubTool,
            runTool: runTool,
            matrix: _matrix,
            coverageArgs: coverageArgs,
            needsFormatting: needsFormatting,
          ).build(),
        ],
      );
}
