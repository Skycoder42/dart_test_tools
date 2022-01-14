import 'package:freezed_annotation/freezed_annotation.dart';

import '../../common/api/expression_builder.dart';
import '../../common/builders/sdk_job_builder.dart';
import '../../common/steps/platforms_builder_mixin.dart';
import '../../types/expression.dart';
import '../../types/id.dart';
import '../../types/job.dart';
import '../../types/matrix.dart';
import '../../types/strategy.dart';
import '../steps/flutter_integration_test_builder.dart';
import 'flutter_sdk_job_builder_mixin.dart';

part 'flutter_integration_test_job_builder.freezed.dart';
part 'flutter_integration_test_job_builder.g.dart';

class _FlutterIntegrationTestJobMatrix
    implements IFlutterIntegrationTestMatrix {
  @override
  final Expression platform;
  @override
  final Expression testDevice;
  @override
  final Expression runPrefix;
  final Expression os;

  const _FlutterIntegrationTestJobMatrix({
    required this.platform,
    required this.testDevice,
    required this.runPrefix,
    required this.os,
  });
}

@freezed
class _PlatformInclude with _$_PlatformInclude {
  const factory _PlatformInclude({
    required String platform,
    required String os,
    // ignore: invalid_annotation_target
    @JsonKey(includeIfNull: false) String? testDevice,
    // ignore: invalid_annotation_target
    @JsonKey(includeIfNull: false) String? runPrefix,
  }) = __PlatformInclude;

  factory _PlatformInclude.fromJson(Map<String, dynamic> json) =>
      _$_PlatformIncludeFromJson(json);
}

class FlutterIntegrationTestJobBuilder extends SdkJobBuilder
    with FlutterSdkJobBuilderMixin {
  static const _matrix = _FlutterIntegrationTestJobMatrix(
    platform: Expression('matrix.platform'),
    testDevice: Expression('matrix.testDevice'),
    runPrefix: Expression('matrix.runPrefix'),
    os: Expression('matrix.os'),
  );

  static const _platformIncludes = [
    // _PlatformInclude(
    //   platform: 'android',
    //   os: 'ubuntu-latest',
    // ),
    // _PlatformInclude(
    //   platform: 'ios',
    //   os: 'macos-latest',
    // ),
    _PlatformInclude(
      platform: 'linux',
      os: 'ubuntu-latest',
      testDevice: '-d linux',
      runPrefix: 'xvfb-run --auto-servernum',
    ),
    _PlatformInclude(
      platform: 'windows',
      os: 'windows-latest',
      testDevice: '-d windows',
    ),
    _PlatformInclude(
      platform: 'macos',
      os: 'macos-latest',
      testDevice: '-d macos',
    ),
    _PlatformInclude(
      platform: 'web',
      os: 'ubuntu-latest',
      testDevice: '-d chrome',
    ),
  ];

  final JobId analyzeJobId;
  @override
  final Expression flutterSdkChannel;
  final Expression repository;
  final Expression workingDirectory;
  final Expression buildRunner;
  final Expression integrationTestSetup;
  final Expression integrationTestPaths;
  final Expression integrationTestProject;
  final Expression platforms;

  FlutterIntegrationTestJobBuilder({
    required this.analyzeJobId,
    required this.flutterSdkChannel,
    required this.repository,
    required this.workingDirectory,
    required this.buildRunner,
    required this.integrationTestSetup,
    required this.integrationTestPaths,
    required this.integrationTestProject,
    required ExpressionBuilderFn<List<String>> platforms,
  }) : platforms = platforms(_platformIncludes.map((i) => i.platform).toList());

  @override
  JobId get id => const JobId('integration_tests');

  @override
  Job build() => Job(
        name: 'Integration tests',
        ifExpression: integrationTestPaths.ne(const Expression.literal('')),
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
          ...FlutterIntegrationTestBuilder(
            repository: repository,
            workingDirectory: workingDirectory,
            buildRunner: buildRunner,
            platforms: platforms,
            integrationTestSetup: integrationTestSetup,
            integrationTestPaths: integrationTestPaths,
            integrationTestProject: integrationTestProject,
            baseTool: baseTool,
            pubTool: pubTool,
            runTool: runTool,
            matrix: _matrix,
          ).build(),
        ],
      );
}
