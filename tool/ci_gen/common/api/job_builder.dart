import '../../types/id.dart';
import '../../types/job.dart';

abstract class JobBuilder {
  JobBuilder._();

  JobId get id;

  Job build();
}
