import 'package:freezed_annotation/freezed_annotation.dart';

import '../../common/jobs/sdk_job_builder.dart';
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
class _PlatformInclude with _$PlatformInclude {
  const factory _PlatformInclude({
    required String platform,
    required String os,
    // ignore: invalid_annotation_target
    @JsonKey(includeIfNull: false) String? dartTestArgs,
  }) = __PlatformInclude;

  // ignore: unused_element
  factory _PlatformInclude.fromJson(Map<String, dynamic> json) =>
      _$PlatformIncludeFromJson(json);
}

final class DartIntegrationTestJobBuilder extends SdkJobBuilder
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
  final Expression workingDirectory;
  final Expression artifactDependencies;
  final Expression buildRunner;
  final Expression buildRunnerArgs;
  final Expression integrationTestSetup;
  final Expression integrationTestPaths;
  final Expression integrationTestEnvVars;
  final Expression integrationTestCacheConfig;

  DartIntegrationTestJobBuilder({
    required this.analyzeJobId,
    required this.dartSdkVersion,
    required this.workingDirectory,
    required this.artifactDependencies,
    required this.buildRunner,
    required this.buildRunnerArgs,
    required this.integrationTestSetup,
    required this.integrationTestPaths,
    required this.integrationTestEnvVars,
    required this.integrationTestCacheConfig,
  });

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
          ...buildSetupSdkSteps(),
          ...DartIntegrationTestBuilder(
            workingDirectory: workingDirectory,
            artifactDependencies: artifactDependencies,
            buildRunner: buildRunner,
            buildRunnerArgs: buildRunnerArgs,
            integrationTestSetup: integrationTestSetup,
            integrationTestPaths: integrationTestPaths,
            integrationTestEnvVars: integrationTestEnvVars,
            integrationTestCacheConfig: integrationTestCacheConfig,
            baseTool: baseTool,
            pubTool: pubTool,
            runTool: runTool,
            matrix: _matrix,
          ).build(),
        ],
      );
}