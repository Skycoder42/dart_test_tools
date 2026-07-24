import 'api/platform_matrix_job_builder_mixin.dart';

enum ArtifactType { appbundle, dmg, msix, archive, flatpak, cli }

enum ArtifactArch { x86_64, aarch64 }

abstract base class Artifacts {
  static String name({
    required Object prefix,
    required Object type,
    required Object platform,
    Object? arch,
  }) {
    final archSuffix = arch == null ? '' : '-${_value(arch)}';
    return '${_value(prefix)}-${_value(type)}-${_value(platform)}$archSuffix';
  }

  static String pattern({
    required Object prefix,
    Object? type,
    Object? platform,
  }) {
    final buffer = StringBuffer(_value(prefix));
    if (type != null) {
      buffer.write('-${_value(type)}');
      if (platform != null) {
        buffer.write('-${_value(platform)}');
      }
    }
    buffer.write('-*');
    return buffer.toString();
  }

  static String _value(Object component) => switch (component) {
    ArtifactType() => component.name,
    ArtifactArch() => component.name,
    IPlatformMatrixSelector() => component.platform,
    _ => component.toString(),
  };
}
