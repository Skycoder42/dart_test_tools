import '../../common/api/step_builder.dart';
import '../../types/expression.dart';
import '../../types/step.dart';

class FlutterSdkBuilder implements StepBuilder {
  final Expression flutterSdkChannel;
  final Expression? ifExpression;

  FlutterSdkBuilder({
    required this.flutterSdkChannel,
    this.ifExpression,
  });

  @override
  Iterable<Step> build() => [
        Step.uses(
          name: 'Install Flutter-SDK '
              '($flutterSdkChannel)',
          ifExpression: ifExpression,
          uses: 'subosito/flutter-action@v1',
          withArgs: {
            'channel': flutterSdkChannel.toString(),
          },
        )
      ];
}
