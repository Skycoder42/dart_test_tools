import '../inputs.dart';
import 'job_config.dart';

base mixin WorkingDirectoryConfig on JobConfig {
  late final workingDirectory = inputContext(WorkflowInputs.workingDirectory);
}
