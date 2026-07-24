import '../../types/id.dart';
import '../../types/step.dart';
import '../api/step_builder.dart';
import '../artifacts.dart';
import '../tools.dart';
import 'resolve_artifact_prefix_builder.dart';

/// Uploads a stage-2 build/bundle artifact and exposes its name.
///
/// Merges the three steps every upload job used to repeat: resolving the
/// artifact-name prefix (see [ResolveArtifactPrefixBuilder]), uploading the
/// artifact under the normalized `<prefix>-<type>-<platform>[-<arch>]` name,
/// and exporting that name (or, for matrix jobs, the wildcard pattern) as a
/// step output so the enclosing job can surface it as a job/workflow output.
///
/// [config] supplies the parts that are uniform across jobs (`artifactPrefix`,
/// `workingDirectory`); the constructor parameters supply what varies per job.
class DeployArtifactBuilder implements StepBuilder {
  static const exportStepId = StepId('export-artifact-name');
  static final artifactNameOutput = exportStepId.output('artifact-name');

  final ResolveArtifactPrefixConfig config;

  /// The artifact [ArtifactType] or an `Expression` resolving to one.
  final Object type;

  /// The platform (`IPlatformMatrixSelector`) or an `Expression`.
  final Object platform;

  /// The optional [ArtifactArch] or an `Expression`.
  final Object? arch;

  /// The path (glob) of the files to upload.
  final String path;

  /// The artifact retention in days.
  final int retentionDays;

  /// The optional upload compression level (used for already-compressed files).
  final int? compressionLevel;

  /// Whether the exported name is the wildcard [Artifacts.pattern] instead of
  /// the exact upload name. Required for matrix jobs, whose concrete name
  /// varies per row and would otherwise be non-deterministic as a job output.
  final bool exportAsPattern;

  /// Whether to emit the [ResolveArtifactPrefixBuilder] step. Set to `false` if
  /// the enclosing job already emits it (e.g. a job that also downloads an
  /// artifact by the resolved prefix before uploading).
  final bool resolvePrefix;

  const DeployArtifactBuilder({
    required this.config,
    required this.type,
    required this.platform,
    this.arch,
    required this.path,
    this.retentionDays = 1,
    this.compressionLevel,
    this.exportAsPattern = false,
    this.resolvePrefix = true,
  });

  @override
  Iterable<Step> build() {
    final prefix = config.resolvedPrefix;
    final artifactName = Artifacts.name(
      prefix: prefix,
      type: type,
      platform: platform,
      arch: arch,
    );
    final exportName = exportAsPattern
        ? Artifacts.pattern(
            prefix: prefix,
            type: type,
            platform: arch != null ? platform : null,
          )
        : artifactName;

    return [
      if (resolvePrefix)
        ...ResolveArtifactPrefixBuilder(config: config).build(),
      Step.uses(
        name: 'Upload artifact',
        uses: Tools.actionsUploadArtifact,
        withArgs: <String, dynamic>{
          'name': artifactName,
          'path': path,
          'retention-days': retentionDays,
          if (compressionLevel != null) 'compression-level': compressionLevel,
          'if-no-files-found': 'error',
        },
      ),
      Step.run(
        id: exportStepId,
        name: 'Export artifact name',
        run: artifactNameOutput.bashSetter(exportName),
        shell: 'bash',
      ),
    ];
  }
}
