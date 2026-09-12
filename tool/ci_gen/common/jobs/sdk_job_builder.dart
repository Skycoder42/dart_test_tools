import 'package:freezed_annotation/freezed_annotation.dart';

import '../../types/expression.dart';
import '../../types/step.dart';
import '../api/job_builder.dart';
import '../api/job_config.dart';

base mixin SdkJobConfig on JobConfig {
  ExpressionOrValue get isFlutter => const ExpressionOrValue.value(false);
  String get baseTool;
  String get pubTool => '$baseTool pub';
  String get runTool => '$pubTool run';
}

abstract base class const SdkJobBuilder<TConfig extends SdkJobConfig>({
  @protected required final TConfig config,
}) implements JobBuilder {
  @protected
  Iterable<Step> buildSetupSdkSteps();
}
