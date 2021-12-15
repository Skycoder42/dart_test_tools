import 'package:freezed_annotation/freezed_annotation.dart';

import '../../types/expression.dart';
import '../../types/job.dart';
import '../../types/matrix.dart';
import '../../types/strategy.dart';
import '../api/job_builder.dart';
import '../api/workflow_input.dart';
import '../inputs.dart';
import '../steps/platforms_builder_mixin.dart';
import '../steps/unit_test_builder.dart';
import 'sdk_job_builder.dart';

part 'unit_test_job_builder.freezed.dart';
part 'unit_test_job_builder.g.dart';

class _UnitTextJobMatrix implements IUnitTextMatrix {
  @override
  final Expression platform;
  final Expression os;
  @override
  final Expression lcovCleanCommand;
  @override
  final Expression dartTestArgs;

  const _UnitTextJobMatrix({
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

  factory _PlatformInclude.fromJson(Map<String, dynamic> json) =>
      _$_PlatformIncludeFromJson(json);
}

abstract class UnitTestJobBuilder extends SdkJobBuilder {
  static const _matrix = _UnitTextJobMatrix(
    platform: Expression('matrix.platform'),
    os: Expression('matrix.os'),
    lcovCleanCommand: Expression('matrix.lcovCleanCommand'),
    dartTestArgs: Expression('matrix.dartTestArgs'),
  );

  const UnitTestJobBuilder();

  @override
  String get name => 'unit_tests';

  @protected
  String get coverageArgs;

  @protected
  bool get needsFormatting;

  @override
  Iterable<WorkflowInput> get inputs => [
        WorkflowInputs.repository,
        WorkflowInputs.workingDirectory,
        WorkflowInputs.buildRunner,
        WorkflowInputs.unitTestPaths,
        WorkflowInputs.minCoverage,
        _platforms,
      ];

  @override
  Job build([Iterable<JobBuilder>? needs]) {
    return Job(
      name: 'Unit tests',
      ifExpression: WorkflowInputs.unitTestPaths.expression
          .ne(const Expression.literal('')),
      needs: needs?.map((jobBuilder) => jobBuilder.name).toList(),
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
        ...buildSetupSdkSteps(
          PlatformsBuilderMixin.createShouldRunExpression(
            _platforms.expression,
            _matrix.platform,
          ),
        ),
        ...UnitTestBuilder(
          repository: WorkflowInputs.repository.expression,
          workingDirectory: WorkflowInputs.workingDirectory.expression,
          buildRunner: WorkflowInputs.buildRunner.expression,
          unitTestPaths: WorkflowInputs.unitTestPaths.expression,
          minCoverage: WorkflowInputs.minCoverage.expression,
          platforms: _platforms.expression,
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

  List<_PlatformInclude> get _platformIncludes => const [
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

  WorkflowInput get _platforms => WorkflowInputs.platforms(
        _platformIncludes.map((p) => p.platform).toList(),
      );
}
