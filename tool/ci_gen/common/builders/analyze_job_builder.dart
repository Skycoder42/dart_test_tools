import '../../types/expression.dart';
import '../../types/job.dart';
import '../api/job_builder.dart';
import '../api/workflow_input.dart';
import '../builder_mixins/analyze_builder_mixin.dart';
import '../builder_mixins/checkout_builder_mixin.dart';
import '../builder_mixins/project_setup_builder_mixin.dart';

abstract class AnalyzeJobBuilder
    with CheckoutBuilderMixin, ProjectSetupBuilderMixin, AnalyzeBuilderMixin
    implements JobBuilder {
  @override
  String get name => 'analyze';

  @override
  Iterable<WorkflowInput> get inputs => [
        ...setupInputs,
        analyzeImageInput,
        publishExcludeInput,
      ];

  @override
  Job build([Iterable<JobBuilder>? needs]) => Job(
        name: 'Analyze',
        runsOn: Expression.input(analyzeImageInput),
        needs: needs?.map((jobBuilder) => jobBuilder.name).toList(),
        steps: [
          ...createSetupSteps(),
          ...createAnalyzeSteps(),
        ],
      );
}
