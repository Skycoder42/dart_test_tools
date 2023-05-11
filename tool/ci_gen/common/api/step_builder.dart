import '../../types/step.dart';

typedef StepBuilderFn = Iterable<Step> Function();

abstract interface class StepBuilder {
  Iterable<Step> build();
}
