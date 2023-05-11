import '../../types/id.dart';
import '../../types/job.dart';

abstract interface class JobBuilder {
  JobId get id;

  Job build();
}
