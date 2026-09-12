import '../common/api/platform_matrix_job_builder_mixin.dart';
import '../types/runs_on.dart';

enum FlutterPlatform(
  @override final String platform,
  @override final RunsOn os, {
  @override required final bool isWeb,
}) implements IPlatformMatrixSelector {
  android('android', RunsOn.ubuntuLatest, isWeb: false),
  ios('ios', RunsOn.macosLatest, isWeb: false),
  linux('linux', RunsOn.ubuntuLatest, isWeb: false),
  macos('macos', RunsOn.macosLatest, isWeb: false),
  windows('windows', RunsOn.windowsLatest, isWeb: false),
  web('web', RunsOn.windowsLatest, isWeb: true);

  static const mobile = [FlutterPlatform.android, FlutterPlatform.ios];

  static const desktop = [
    FlutterPlatform.linux,
    FlutterPlatform.macos,
    FlutterPlatform.windows,
  ];
}
