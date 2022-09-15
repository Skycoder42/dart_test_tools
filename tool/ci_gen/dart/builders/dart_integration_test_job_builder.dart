import 'package:freezed_annotation/freezed_annotation.dart';

import '../../common/api/expression_builder.dart';
import '../../common/builders/sdk_job_builder.dart';
import '../../common/steps/platforms_builder_mixin.dart';
import '../../types/expression.dart';
import '../../types/id.dart';
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

  // ignore: unused_element
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

  static const _platformIncludes = [
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

  final JobId analyzeJobId;
  @override
  final Expression dartSdkVersion;
  final Expression repository;
  final Expression workingDirectory;
  final Expression releaseRef;
  final Expression buildRunner;
  final Expression integrationTestSetup;
  final Expression integrationTestPaths;
  final Expression integrationTestEnvVars;
  final Expression platforms;

  DartIntegrationTestJobBuilder({
    required this.analyzeJobId,
    required this.dartSdkVersion,
    required this.repository,
    required this.workingDirectory,
    required this.releaseRef,
    required this.buildRunner,
    required this.integrationTestSetup,
    required this.integrationTestPaths,
    required this.integrationTestEnvVars,
    required ExpressionBuilderFn<List<String>> platforms,
  }) : platforms = platforms(_platformIncludes.map((i) => i.platform).toList());

  @override
  JobId get id => const JobId('integration_tests');

  @override
  Job build() => Job(
        name: 'Integration tests',
        ifExpression: integrationTestPaths.ne(Expression.empty),
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
          ...buildSetupSdkSteps(
            PlatformsBuilderMixin.createShouldRunExpression(
              platforms,
              _matrix.platform,
            ),
          ),
          ...DartIntegrationTestBuilder(
            repository: repository,
            workingDirectory: workingDirectory,
            releaseRef: releaseRef,
            buildRunner: buildRunner,
            integrationTestSetup: integrationTestSetup,
            integrationTestPaths: integrationTestPaths,
            integrationTestEnvVars: integrationTestEnvVars,
            platforms: platforms,
            baseTool: baseTool,
            pubTool: pubTool,
            runTool: runTool,
            matrix: _matrix,
          ).build(),
        ],
      );
}
