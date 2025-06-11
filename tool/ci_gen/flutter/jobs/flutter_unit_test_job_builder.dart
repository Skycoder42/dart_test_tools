import '../../common/api/matrix_job_builder_mixin.dart';
import '../../common/api/platform_matrix_job_builder_mixin.dart';
import '../../common/inputs.dart';
import '../../common/jobs/unit_test_job_builder.dart';
import '../../dart/dart_platform.dart';
import '../../types/expression.dart';
import 'flutter_sdk_job_builder_mixin.dart';

final class FlutterCoverageArgsMatrixProperty
    extends IMatrixProperty<IPlatformMatrixSelector> {
  const FlutterCoverageArgsMatrixProperty();

  @override
  String get name => 'coverageArgs';

  @override
  Object? valueFor(IPlatformMatrixSelector selector) => switch (selector) {
    IPlatformMatrixSelector(isWeb: true) => '',
    _ => '--coverage',
  };
}

class FlutterUnitTestMatrix extends UnitTestMatrix {
  const FlutterUnitTestMatrix() : super(DartPlatform.values);

  FlutterCoverageArgsMatrixProperty get coverageArgs =>
      const FlutterCoverageArgsMatrixProperty();

  @override
  List<IMatrixProperty<IPlatformMatrixSelector>> get includeProperties => [
    ...super.includeProperties,
    coverageArgs,
  ];
}

final class FlutterUnitTestJobConfig extends UnitTestJobConfig
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

  FlutterUnitTestJobConfig(super.inputContext, super.secretContext);
}

final class FlutterUnitTestJobBuilder
    extends UnitTestJobBuilder<FlutterUnitTestJobConfig>
    with FlutterSdkJobBuilderMixin<FlutterUnitTestJobConfig> {
  FlutterUnitTestJobBuilder({
    required super.enabledPlatformsOutput,
    required super.config,
  }) : super(
         platformSelectors: DartPlatform.values,
         matrix: const FlutterUnitTestMatrix(),
       );
}
