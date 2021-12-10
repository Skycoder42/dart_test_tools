import '../common/api/workflow_input.dart';
import '../types/on.dart';
import '../types/workflow.dart';
import '../types/workflow_call.dart';
import 'builders/dart_analyze_job_builder.dart';
import 'builders/dart_unit_test_job_builder.dart';

abstract class DartWorkflow {
  static const defaultPlatforms = ['linux', 'windows', 'macos', 'web'];

  static Workflow buildWorkflow() {
    final analyzeJobBuilder = DartAnalyzeJobBuilder();
    final unitTestBulder = DartUnitTestJobBuilder();

    // combine all inputs of all builders
    final inputs = <WorkflowInput>{
      ...analyzeJobBuilder.inputs,
      ...unitTestBulder.inputs,
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
      },
    );
  }
}
