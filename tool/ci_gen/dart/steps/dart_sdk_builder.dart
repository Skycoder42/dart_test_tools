import '../../common/api/step_builder.dart';
import '../../common/tools.dart';
import '../../types/expression.dart';
import '../../types/step.dart';

class DartSdkBuilder({
  required final Expression dartSdkVersion,
  final Expression? ifExpression,
}) implements StepBuilder {
  @override
  Iterable<Step> build() => [
    Step.uses(
      name: 'Install Dart-SDK ($dartSdkVersion)',
      ifExpression: ifExpression,
      uses: Tools.dartLangSetupDart,
      withArgs: <String, dynamic>{'sdk': dartSdkVersion.toString()},
    ),
  ];
}
