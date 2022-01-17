import '../../common/api/step_builder.dart';
import '../../types/expression.dart';
import '../../types/step.dart';

class FlutterSdkBuilder implements StepBuilder {
  final Expression flutterSdkChannel;
  final Expression? ifExpression;
  final String? preCacheTarget;

  FlutterSdkBuilder({
    required this.flutterSdkChannel,
    this.ifExpression,
    this.preCacheTarget,
  });

  @override
  Iterable<Step> build() => [
        Step.uses(
          name: 'Install Flutter-SDK '
              '($flutterSdkChannel)',
          ifExpression: ifExpression,
          uses: 'subosito/flutter-action@v1',
          withArgs: <String, dynamic>{
            'channel': flutterSdkChannel.toString(),
          },
        ),
        Step.run(
          name: 'Download flutter binary artifacts',
          ifExpression: ifExpression,
          run: 'flutter precache --universal$_preCacheTargetArgs',
        ),
      ];

  String get _preCacheTargetArgs =>
      preCacheTarget != null ? ' --$preCacheTarget' : '';
}
