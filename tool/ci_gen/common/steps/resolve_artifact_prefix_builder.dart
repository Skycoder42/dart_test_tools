import '../../types/expression.dart';
import '../../types/id.dart';
import '../../types/step.dart';
import '../api/job_config.dart';
import '../api/step_builder.dart';
import '../api/working_directory_config.dart';
import '../inputs.dart';

/// Configuration for jobs that resolve the artifact-name prefix.
///
/// Provides the `artifactPrefix` input (and, via [WorkingDirectoryConfig], the
/// `workingDirectory`) needed to compute the normalized artifact name.
base mixin ResolveArtifactPrefixConfig on JobConfig, WorkingDirectoryConfig {
  late final artifactPrefix = inputContext(WorkflowInputs.artifactPrefix);

  /// The prefix expression: the `artifactPrefix` input if set, otherwise the
  /// package name resolved by the [ResolveArtifactPrefixBuilder] step.
  Expression get resolvedPrefix =>
      artifactPrefix | ResolveArtifactPrefixBuilder.output.expression;
}

/// Emits a step that resolves the artifact-name prefix at runtime.
///
/// When the `artifactPrefix` input is empty, it falls back to the package name
/// read from the `pubspec.yaml` in the configured working directory. Both
/// stage-2 uploads and stage-4 downloads compose the artifact name from
/// [ResolveArtifactPrefixConfig.resolvedPrefix] over the same checked-out
/// `pubspec.yaml`, so the names line up without any explicit wiring.
class ResolveArtifactPrefixBuilder implements StepBuilder {
  static const stepId = StepId('resolve-artifact-prefix');
  static final output = stepId.output('prefix');

  final ResolveArtifactPrefixConfig config;

  const ResolveArtifactPrefixBuilder({required this.config});

  @override
  Iterable<Step> build() => [
    Step.run(
      id: stepId,
      name: 'Resolve artifact prefix',
      ifExpression: config.artifactPrefix.eq(Expression.empty),
      run: output.bashSetter('yq -r .name pubspec.yaml', isCommand: true),
      workingDirectory: config.workingDirectory.toString(),
      shell: 'bash',
    ),
  ];
}
