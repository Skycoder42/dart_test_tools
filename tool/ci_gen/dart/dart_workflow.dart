import '../common/api/workflow_input.dart';
import '../common/builders/validate_coverage_job_builder.dart';
import '../types/on.dart';
import '../types/workflow.dart';
import '../types/workflow_call.dart';
import 'builders/dart_analyze_job_builder.dart';
import 'builders/dart_unit_test_job_builder.dart';

abstract class DartWorkflow {
  static const defaultPlatforms = ['linux', 'windows', 'macos', 'web'];

  static Workflow buildWorkflow() {
    const analyzeJobBuilder = DartAnalyzeJobBuilder();
    const unitTestBulder = DartUnitTestJobBuilder();
    const validateCoverageBuilder = ValidateCoverageJobBuilder();

    // combine all inputs of all builders
    final inputs = <WorkflowInput>{
      ...analyzeJobBuilder.inputs,
      ...unitTestBulder.inputs,
      ...validateCoverageBuilder.inputs,
    };

    return Workflow(
      on: On(
        workflowCall: WorkflowCall(
          inputs: {
            for (final input in inputs) input.name: input.input,
          },
        ),
      ),
      jobs: {
        analyzeJobBuilder.name: analyzeJobBuilder.build(),
        unitTestBulder.name: unitTestBulder.build([analyzeJobBuilder]),
        validateCoverageBuilder.name:
            validateCoverageBuilder.build([unitTestBulder]),
      },
    );
  }
}
