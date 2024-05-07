import '../common/api/platform_matrix_job_builder_mixin.dart';
import '../types/runs_on.dart';

enum FlutterPlatform implements IPlatformMatrixSelector {
  android('android', RunsOn.macosLatestX86, false),
  ios('ios', RunsOn.macosLatestArm64, false),
  linux('linux', RunsOn.ubuntuLatest, false),
  macos('macos', RunsOn.macosLatestArm64, false),
  windows('windows', RunsOn.windowsLatest, false),
  web('web', RunsOn.windowsLatest, true);

  @override
  final String platform;

  @override
  final RunsOn os;

  @override
  final bool isWeb;

  const FlutterPlatform(this.platform, this.os, this.isWeb);
}
