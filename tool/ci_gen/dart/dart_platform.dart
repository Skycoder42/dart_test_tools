import '../common/api/platform_matrix_job_builder_mixin.dart';
import '../types/runs_on.dart';

enum DartPlatform implements IPlatformMatrixSelector {
  linux('linux', RunsOn.ubuntuLatest, false),
  macos('macos', RunsOn.macosLatest, false),
  windows('windows', RunsOn.windowsLatest, false),
  web('web', RunsOn.ubuntuLatest, true);

  @override
  final String platform;

  @override
  final RunsOn os;

  @override
  final bool isWeb;

  // ignore: avoid_positional_boolean_parameters private constructor
  const DartPlatform(this.platform, this.os, this.isWeb);
}
