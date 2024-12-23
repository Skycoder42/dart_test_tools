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

abstract base class SdkJobBuilder<TConfig extends SdkJobConfig>
    implements JobBuilder {
  @protected
  final TConfig config;

  const SdkJobBuilder({required this.config});

  @protected
  Iterable<Step> buildSetupSdkSteps();
}
