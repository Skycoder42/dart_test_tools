import '../../common/api/step_builder.dart';
import '../../types/expression.dart';
import '../../types/step.dart';

class FlutterSdkBuilder implements StepBuilder {
  final Expression flutterSdkChannel;
  final Expression? buildPlatform;
  final Expression? enableDesktopCondition;
  final Expression? ifExpression;

  const FlutterSdkBuilder({
    required this.flutterSdkChannel,
    this.buildPlatform,
    this.enableDesktopCondition,
    this.ifExpression,
  }) : assert(
          enableDesktopCondition == null || buildPlatform != null,
          'If enableDesktopCondition is set, buildPlatform must be too',
        );

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
        if (enableDesktopCondition != null)
          Step.run(
            name: 'Enable experimental platforms',
            ifExpression: enableDesktopCondition! & ifExpression,
            run: 'flutter config --enable-$buildPlatform-desktop',
          ),
        Step.run(
          name: 'Download flutter binary artifacts',
          ifExpression: ifExpression,
          run: 'flutter precache --universal$_preCachePlatformArgs',
        ),
      ];

  String get _preCachePlatformArgs =>
      buildPlatform != null ? ' --$buildPlatform' : '';
}
