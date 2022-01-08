import '../../common/api/job_builder.dart';
import '../../types/expression.dart';
import '../../types/id.dart';
import '../../types/job.dart';
import '../../types/matrix.dart';
import '../../types/strategy.dart';

class CompileJobBuilder implements JobBuilder {
  @override
  JobId get id => const JobId('compile');

  @override
  Job build() => Job(
        name: 'Create compiled artifacts',
        strategy: Strategy(
          failFast: false,
          matrix: Matrix.expression(Expression('')),
        ),
        runsOn: null,
        steps: [],
      );
}
