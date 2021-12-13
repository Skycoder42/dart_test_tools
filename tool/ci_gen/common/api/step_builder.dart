import '../../types/step.dart';

typedef StepBuilderFn = Iterable<Step> Function();

abstract class StepBuilder {
  StepBuilder._();

  Iterable<Step> build();
}
