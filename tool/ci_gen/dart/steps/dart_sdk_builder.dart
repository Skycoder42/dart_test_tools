import '../../common/api/step_builder.dart';
import '../../types/expression.dart';
import '../../types/step.dart';

class DartSdkBuilder implements StepBuilder {
  final Expression dartSdkVersion;
  final Expression? ifExpression;

  DartSdkBuilder({
    required this.dartSdkVersion,
    this.ifExpression,
  });

  @override
  Iterable<Step> build() => [
        Step.uses(
          name: 'Install Dart-SDK '
              '($dartSdkVersion)',
          ifExpression: ifExpression,
          uses: 'dart-lang/setup-dart@v1.3',
          withArgs: {
            'sdk': dartSdkVersion.toString(),
          },
        )
      ];
}
