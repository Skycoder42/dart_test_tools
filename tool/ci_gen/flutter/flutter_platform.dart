import '../common/api/platform_matrix_job_builder_mixin.dart';
import '../types/runs_on.dart';

enum FlutterPlatform implements IPlatformMatrixSelector {
  android('android', RunsOn.ubuntuLatest, false),
  ios('ios', RunsOn.macosLatest, false),
  linux('linux', RunsOn.ubuntuLatest, false),
  macos('macos', RunsOn.macosLatest, false),
  windows('windows', RunsOn.windowsLatest, false),
  web('web', RunsOn.windowsLatest, true);

  @override
  final String platform;

  @override
  final RunsOn os;

  @override
  final bool isWeb;

  // ignore: avoid_positional_boolean_parameters
  const FlutterPlatform(this.platform, this.os, this.isWeb);

  static const mobile = [FlutterPlatform.android, FlutterPlatform.ios];

  static const desktop = [
    FlutterPlatform.linux,
    FlutterPlatform.macos,
    FlutterPlatform.windows,
  ];
}
