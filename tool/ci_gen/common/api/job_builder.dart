import '../../types/job.dart';

abstract class JobBuilder {
  JobBuilder._();

  String get name;

  Job build([Iterable<JobBuilder>? needs]);
}
