import 'package:freezed_annotation/freezed_annotation.dart';

import '../../common/api/job_builder.dart';
import '../../common/api/workflow_input.dart';
import '../../common/builders/sdk_job_builder.dart';
import '../../common/inputs.dart';
import '../../common/steps/platforms_builder_mixin.dart';
import '../../types/expression.dart';
import '../../types/job.dart';
import '../../types/matrix.dart';
import '../../types/strategy.dart';
import '../steps/dart_integration_test_builder.dart';
import 'dart_sdk_job_builder_mixin.dart';

part 'dart_integration_test_job_builder.freezed.dart';
part 'dart_integration_test_job_builder.g.dart';

class _DartIntegrationTestJobMatrix implements IDartIntegrationTestMatrix {
  @override
  final Expression platform;
  @override
  final Expression dartTestArgs;
  final Expression os;

  const _DartIntegrationTestJobMatrix({
    required this.platform,
    required this.dartTestArgs,
    required this.os,
  });
}

@freezed
class _PlatformInclude with _$_PlatformInclude {
  const factory _PlatformInclude({
    required String platform,
    required String os,
    // ignore: invalid_annotation_target
    @JsonKey(includeIfNull: false) String? dartTestArgs,
  }) = __PlatformInclude;

  factory _PlatformInclude.fromJson(Map<String, dynamic> json) =>
      _$_PlatformIncludeFromJson(json);
}

class DartIntegrationTestJobBuilder extends SdkJobBuilder
    with DartSdkJobBuilderMixin {
  static const _matrix = _DartIntegrationTestJobMatrix(
    platform: Expression('matrix.platform'),
    dartTestArgs: Expression('matrix.dartTestArgs'),
    os: Expression('matrix.os'),
  );

  const DartIntegrationTestJobBuilder();

  @override
  String get name => 'integration_tests';

  @override
  Iterable<WorkflowInput> get inputs => [
        WorkflowInputs.repository,
        WorkflowInputs.workingDirectory,
        WorkflowInputs.buildRunner,
        WorkflowInputs.integrationTestSetup,
        WorkflowInputs.integrationTestPaths,
        _platforms,
      ];

  @override
  Job build([Iterable<JobBuilder>? needs]) => Job(
        name: 'Integration tests',
        ifExpression: WorkflowInputs.integrationTestPaths.expression
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
          ...DartIntegrationTestBuilder(
            repository: WorkflowInputs.repository.expression,
            workingDirectory: WorkflowInputs.workingDirectory.expression,
            buildRunner: WorkflowInputs.buildRunner.expression,
            integrationTestSetup:
                WorkflowInputs.integrationTestSetup.expression,
            integrationTestPaths:
                WorkflowInputs.integrationTestPaths.expression,
            platforms: _platforms.expression,
            baseTool: baseTool,
            pubTool: pubTool,
            runTool: runTool,
            matrix: _matrix,
          ).build(),
        ],
      );

  List<_PlatformInclude> get _platformIncludes => const [
        _PlatformInclude(
          platform: 'linux',
          os: 'ubuntu-latest',
        ),
        _PlatformInclude(
          platform: 'windows',
          os: 'windows-latest',
        ),
        _PlatformInclude(
          platform: 'macos',
          os: 'macos-latest',
        ),
        _PlatformInclude(
          platform: 'web',
          os: 'ubuntu-latest',
          dartTestArgs: '-p chrome',
        ),
      ];

  WorkflowInput get _platforms => WorkflowInputs.platforms(
        _platformIncludes.map((p) => p.platform).toList(),
      );
}
