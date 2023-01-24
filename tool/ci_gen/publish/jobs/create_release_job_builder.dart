import '../../common/api/job_builder.dart';
import '../../common/steps/release_entry_builder.dart';
import '../../types/expression.dart';
import '../../types/id.dart';
import '../../types/job.dart';

class CreateReleaseJobBuilder implements JobBuilder {
  static const jobId = JobId('createRelease');

  CreateReleaseJobBuilder();

  @override
  JobId get id => jobId;

  @override
  Job build() => Job(
        name: 'Create release if needed',
        runsOn: 'ubuntu-latest',
        steps: [
          ...ReleaseEntryBuilder(
            ref: _eventParam('ref'),
            tag: _eventParam('tag'),
            name: _eventParam('name'),
            body: _eventParam('body'),
          ).build(),
        ],
      );

  Expression _eventParam(String name) =>
      Expression('github.event.client_payload.$name');
}
