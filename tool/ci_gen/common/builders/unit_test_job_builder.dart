import 'package:freezed_annotation/freezed_annotation.dart';

import '../../types/expression.dart';
import '../../types/input.dart';
import '../../types/job.dart';
import '../../types/matrix.dart';
import '../../types/step.dart';
import '../../types/strategy.dart';
import '../api/job_builder.dart';
import '../api/workflow_input.dart';
import '../builder_mixins/coverage_collector_builder_mixin.dart';
import '../builder_mixins/platforms_builder_mixin.dart';
import '../builder_mixins/project_setup_builder_mixin.dart';

part 'unit_test_job_builder.freezed.dart';
part 'unit_test_job_builder.g.dart';

@freezed
class PlatformInclude with _$PlatformInclude {
  const factory PlatformInclude({
    required String platform,
    required String os,
    required String lcovCleanCommand,
    // ignore: invalid_annotation_target
    @JsonKey(includeIfNull: false) String? dartTestArgs,
  }) = _PlatformInclude;

  factory PlatformInclude.fromJson(Map<String, dynamic> json) =>
      _$PlatformIncludeFromJson(json);
}

abstract class UnitTestJobBuilder
    with
        ProjectSetupBuilderMixin,
        PlatformsBuilderMixin,
        CoverageCollectorBuilderMixin
    implements JobBuilder {
  @protected
  final unitTestPathsInput = const WorkflowInput(
    name: 'unitTestPaths',
    input: Input(
      type: Type.string,
      required: false,
      defaultValue: 'test',
      description: 'Specifiy directories or paths of unit tests to run. '
          'By default, all test in the test directory are run.',
    ),
  );

  static const _matrixExpressions = PlatformInclude(
    platform: 'matrix.platform',
    os: 'matrix.os',
    lcovCleanCommand: 'matrix.lcovCleanCommand',
    dartTestArgs: 'matrix.dartTestArgs',
  );

  @override
  String get name => 'unit_tests';

  @protected
  String get runCoverageArgs;

  @override
  List<String> get supportedPlatforms =>
      platformIncludes.map((include) => include.platform).toList();

  @override
  Iterable<WorkflowInput> get inputs => [
        ...setupInputs,
        ...platformsInputs,
        unitTestPathsInput,
        ...coverageCollectorInputs,
      ];

  @override
  Job build([Iterable<JobBuilder>? needs]) {
    return Job(
      name: 'Unit tests',
      ifExpression: "${unitTestPathsInput.expression} != ''",
      needs: needs?.map((jobBuilder) => jobBuilder.name).toList(),
      strategy: Strategy(
        failFast: false,
        matrix: Matrix(
          {
            'platform': platformIncludes.map((i) => i.platform).toList(),
          },
          include: platformIncludes.map((i) => i.toJson()).toList(),
        ),
      ),
      runsOn: Expression.create(_matrixExpressions.os),
      steps: [
        ...createSetupSteps(),
        Step.run(
          name: 'Run unit tests',
          ifExpression: shouldRunExpression(_matrixExpressions.platform),
          run:
              '$baseTool test ${Expression.create(_matrixExpressions.dartTestArgs!)} '
              '$runCoverageArgs ${Expression.input(unitTestPathsInput)}',
          workingDirectory: Expression.input(workingDirectoryInput),
        ),
        ...createCoverageCollectorSteps(
          platformExpression: _matrixExpressions.platform,
          lcovCleanCommandExpression: _matrixExpressions.lcovCleanCommand,
        ),
      ],
    );
  }

  List<PlatformInclude> get platformIncludes => const [
        PlatformInclude(
          platform: 'linux',
          os: 'ubuntu-latest',
          lcovCleanCommand: r'sed -i "s#SF:$PWD/#SF:#g" coverage/lcov.info',
        ),
        PlatformInclude(
          platform: 'windows',
          os: 'windows-latest',
          lcovCleanCommand:
              r'(Get-Content coverage\lcov.info).replace("SF:$PWD\", "SF:").replace("\", "/") | Set-Content coverage\lcov.info',
        ),
        PlatformInclude(
          platform: 'macos',
          os: 'macos-latest',
          lcovCleanCommand: r'sed -i "" "s#SF:$PWD/#SF:#g" coverage/lcov.info',
        ),
        PlatformInclude(
          platform: 'web',
          os: 'ubuntu-latest',
          lcovCleanCommand: r'sed -i "s#SF:$PWD/#SF:#g" coverage/lcov.info',
          dartTestArgs: '-p chrome',
        ),
      ];
}
