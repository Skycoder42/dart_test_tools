import '../common/api/platform_matrix_job_builder_mixin.dart';
import '../types/runs_on.dart';

enum DartPlatform(
  @override final String platform,
  @override final RunsOn os, {
  @override required final bool isWeb,
}) implements IPlatformMatrixSelector {
  linux('linux', RunsOn.ubuntuLatest, isWeb: false),
  macos('macos', RunsOn.macosLatest, isWeb: false),
  windows('windows', RunsOn.windowsLatest, isWeb: false),
  web('web', RunsOn.ubuntuLatest, isWeb: true),
}
