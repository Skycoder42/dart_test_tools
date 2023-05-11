import 'package:freezed_annotation/freezed_annotation.dart';

import '../../types/step.dart';
import '../api/job_builder.dart';

abstract base class SdkJobBuilder implements JobBuilder {
  const SdkJobBuilder();

  @protected
  String get baseTool;

  @protected
  String get pubTool => '$baseTool pub';

  @protected
  String get runTool => '$pubTool run';

  @protected
  Iterable<Step> buildSetupSdkSteps();
}
