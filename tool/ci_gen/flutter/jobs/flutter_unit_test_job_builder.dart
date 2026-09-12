import '../../common/api/matrix_job_builder_mixin.dart';
import '../../common/api/platform_matrix_job_builder_mixin.dart';
import '../../common/inputs.dart';
import '../../common/jobs/unit_test_job_builder.dart';
import '../../dart/dart_platform.dart';
import '../../types/expression.dart';
import 'flutter_sdk_job_builder_mixin.dart';

final class const FlutterCoverageArgsMatrixProperty()
    extends IMatrixProperty<IPlatformMatrixSelector> {
  @override
  String get name => 'coverageArgs';

  @override
  Object? valueFor(IPlatformMatrixSelector selector) => switch (selector) {
    IPlatformMatrixSelector(isWeb: true) => '',
    _ => '--coverage',
  };
}

class const FlutterUnitTestMatrix() extends UnitTestMatrix {
  this : super(DartPlatform.values);

  FlutterCoverageArgsMatrixProperty get coverageArgs =>
      const FlutterCoverageArgsMatrixProperty();

  @override
  List<IMatrixProperty<IPlatformMatrixSelector>> get includeProperties => [
    ...super.includeProperties,
    coverageArgs,
  ];
}

final class FlutterUnitTestJobConfig(super.inputContext, super.secretContext)
    extends UnitTestJobConfig
    with FlutterSdkJobConfig {
  @override
  late final javaJdkVersion = inputContext(WorkflowInputs.javaJdkVersion);

  @override
  String get coverageArgs =>
      const FlutterCoverageArgsMatrixProperty().expression.toString();

  @override
  Expression get runCoverageExpression =>
      super.runCoverageExpression &
      const FlutterCoverageArgsMatrixProperty().expression.ne(Expression.empty);

  @override
  bool get needsFormatting => false;
}

final class FlutterUnitTestJobBuilder({
  required super.enabledPlatformsOutput,
  required super.config,
}) extends UnitTestJobBuilder<FlutterUnitTestJobConfig>
    with FlutterSdkJobBuilderMixin<FlutterUnitTestJobConfig> {
  this
    : super(
        platformSelectors: DartPlatform.values,
        matrix: const FlutterUnitTestMatrix(),
      );
}
