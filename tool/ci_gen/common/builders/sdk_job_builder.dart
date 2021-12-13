import 'package:freezed_annotation/freezed_annotation.dart';

import '../../types/step.dart';
import '../api/job_builder.dart';
import '../api/workflow_input.dart';

abstract class SdkJobBuilder implements JobBuilder {
  @protected
  String get baseTool;

  @protected
  String get pubTool => '$baseTool pub';

  @protected
  String get runTool => '$pubTool run';

  @protected
  Iterable<WorkflowInput> get setupSdkInputs;

  @protected
  Iterable<Step> buildSetupSdkSteps();
}
