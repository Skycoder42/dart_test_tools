import '../../types/id.dart';
import '../../types/job.dart';

abstract class JobBuilder {
  JobBuilder._();

  JobId get id;

  Job build([Iterable<JobBuilder>? needs]);
}

extension JobIdListX on Iterable<JobBuilder> {
  List<JobId> get ids => map((j) => j.id).toList();
}
