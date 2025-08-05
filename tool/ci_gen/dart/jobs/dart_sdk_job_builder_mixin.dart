import '../../common/inputs.dart';
import '../../common/jobs/sdk_job_builder.dart';
import '../../flutter/steps/flutter_sdk_builder.dart';
import '../../types/expression.dart';
import '../../types/step.dart';
import '../steps/dart_sdk_builder.dart';

base mixin DartSdkJobConfig on SdkJobConfig {
  late final dartSdkVersion = inputContext(WorkflowInputs.dartSdkVersion);
  late final flutterSdkChannel = inputContext(WorkflowInputs.flutterSdkChannel);
  late final ExpressionOrValue needsFlutterSdk = const ExpressionOrValue.value(
    false,
  );

  @override
  String get baseTool => 'dart';

  @override
  String get runTool => '$baseTool run';
}

base mixin DartSdkJobBuilderMixin<TConfig extends DartSdkJobConfig>
    on SdkJobBuilder<TConfig> {
  @override
  Iterable<Step> buildSetupSdkSteps() => [
    ...switch (config.needsFlutterSdk) {
      ExpressionOrValueValue(:final bool value) =>
        value
            ? FlutterSdkBuilder(
                flutterSdkChannel: config.flutterSdkChannel,
              ).build()
            : DartSdkBuilder(dartSdkVersion: config.dartSdkVersion).build(),
      ExpressionOrValueExpression(:final expression) => [
        ...DartSdkBuilder(
          dartSdkVersion: config.dartSdkVersion,
          ifExpression: expression.not,
        ).build(),
        ...FlutterSdkBuilder(
          flutterSdkChannel: config.flutterSdkChannel,
          ifExpression: expression,
        ).build(),
      ],
      _ => throw ArgumentError.value(config.needsFlutterSdk, 'needsFlutterSdk'),
    },
  ];
}
