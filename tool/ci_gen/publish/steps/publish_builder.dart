import '../../common/api/job_config.dart';
import '../../common/api/step_builder.dart';
import '../../common/inputs.dart';
import '../../common/steps/project_setup_builder.dart';
import '../../common/steps/run_publish_builder.dart';
import '../../common/tools.dart';
import '../../types/expression.dart';
import '../../types/id.dart';
import '../../types/step.dart';

base mixin PublishConfig on JobConfig, ProjectSetupConfig, RunPublishConfig {
  late final prePublish = inputContext(WorkflowInputs.prePublish);
  late final extraArtifacts = inputContext(WorkflowInputs.extraArtifacts);

  @override
  late final withSubmodules = inputContext(WorkflowInputs.withSubmodules);

  @override
  late final isFlutter = ExpressionOrValue.expression(
    inputContext(WorkflowInputs.flutter),
  );

  @override
  String get baseTool =>
      throw UnsupportedError('baseTool cannot be accessed in publish workflow');

  @override
  late final pubTool = PublishBuilder.toolsPub.expression.toString();

  @override
  late final runTool = PublishBuilder.toolsPubRun.expression.toString();

  @override
  bool get skipYqInstall => true;

  @override
  bool get releaseMode => true;
}

class PublishBuilder implements StepBuilder {
  static const toolsStepId = StepId('tools');
  static final toolsPub = toolsStepId.output('pub');
  static final toolsPubRun = toolsStepId.output('pubRun');

  final PublishConfig config;

  PublishBuilder({required this.config});

  @override
  Iterable<Step> build() => [
    Step.run(
      id: toolsStepId,
      name: 'Prepare build tools',
      run:
          '''
if ${config.isFlutter.asExpression}; then
  ${toolsPub.bashSetter('flutter pub')}
  ${toolsPubRun.bashSetter('flutter pub run')}
else
  ${toolsPub.bashSetter('dart pub')}
  ${toolsPubRun.bashSetter('dart run')}
fi
''',
    ),
    ...ProjectSetupBuilder(config: config).build(),
    Step.uses(
      name: 'Download additional artifacts',
      ifExpression: config.extraArtifacts.ne(Expression.empty),
      uses: Tools.actionsDownloadArtifact,
      withArgs: <String, dynamic>{
        for (final key in ['name', 'path']) key: _artifactConfig(key),
      },
    ),
    Step.run(
      name: 'Run pre publish script',
      ifExpression: config.prePublish.ne(Expression.empty),
      run: config.prePublish.toString(),
      workingDirectory: config.workingDirectory.toString(),
    ),
    ...RunPublishBuilder(
      config: config,
      publishStepName: 'Publish package',
      publishArgs: '--force',
    ).build(),
  ];

  String _artifactConfig(String key) =>
      Expression("fromJSON(${config.extraArtifacts.value})['$key']").toString();
}
