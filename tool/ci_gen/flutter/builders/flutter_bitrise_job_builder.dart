import '../../common/api/job_builder.dart';
import '../../types/expression.dart';
import '../../types/job.dart';
import '../../types/id.dart';
import '../steps/run_bitrise_workflow_builder.dart';

class FlutterBitriseJobBuilder implements JobBuilder {
  final JobId analyzeJobId;
  final Expression bitriseAppSlug;
  final Expression bitriseWorkflowId;
  final Expression bitrisePat;

  FlutterBitriseJobBuilder({
    required this.analyzeJobId,
    required this.bitriseAppSlug,
    required this.bitriseWorkflowId,
    required this.bitrisePat,
  });

  @override
  JobId get id => JobId('bitrise_integration_tests');

  @override
  Job build() => Job(
        name: 'Bitrise integration tests',
        needs: {analyzeJobId},
        ifExpression: bitriseAppSlug.ne(Expression.empty),
        runsOn: 'ubuntu-latest',
        steps: [
          ...RunBitriseWorkflowBuilder(
            bitriseAppSlug: bitriseAppSlug,
            bitriseWorkflowId: bitriseWorkflowId,
            bitrisePat: bitrisePat,
          ).build(),
        ],
      );
}
