import '../../common/api/step_builder.dart';
import '../../common/tools.dart';
import '../../types/expression.dart';
import '../../types/step.dart';
import '../flutter_platform.dart';

class FlutterSdkBuilder implements StepBuilder {
  final Expression flutterSdkChannel;
  final ExpressionOrValue? buildPlatform;
  final Expression? javaJdkVersion;
  final Expression? ifExpression;

  const FlutterSdkBuilder({
    required this.flutterSdkChannel,
    this.buildPlatform,
    this.javaJdkVersion,
    this.ifExpression,
  });

  @override
  Iterable<Step> build() => [
        if (_maybeSetupJdk() case final Step step) step,
        Step.uses(
          name: 'Install Flutter-SDK ($flutterSdkChannel)',
          ifExpression: ifExpression,
          uses: Tools.subositoFlutterAction,
          withArgs: <String, dynamic>{
            'channel': flutterSdkChannel.toString(),
            'cache': true,
          },
        ),
        Step.run(
          name: 'Download flutter binary artifacts',
          ifExpression: ifExpression,
          run: 'flutter precache --universal$_preCachePlatformArgs',
        ),
      ];

  String get _preCachePlatformArgs =>
      buildPlatform != null ? ' --$buildPlatform' : '';

  Step? _maybeSetupJdk() => javaJdkVersion == null
      ? null
      : buildPlatform?.when(
          expression: (expression) => _setupJdk(
            expression.eq(Expression.literal(FlutterPlatform.android.platform)),
          ),
          value: (value) => value == FlutterPlatform.android.platform
              ? _setupJdk(null)
              : null,
        );

  Step _setupJdk(Expression? condition) => Step.uses(
        name: 'Install JDK Version $javaJdkVersion',
        ifExpression:
            condition != null ? condition & ifExpression : ifExpression,
        uses: Tools.actionsSetupJava,
        withArgs: <String, dynamic>{
          'distribution': 'temurin',
          'java-version': javaJdkVersion.toString(),
        },
      );
}
