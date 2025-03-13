import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:path/path.dart';

part 'analysis_options_ref.freezed.dart';

@freezed
sealed class AnalysisOptionsRef with _$AnalysisOptionsRef {
  const AnalysisOptionsRef._();

  const factory AnalysisOptionsRef.package({
    required String packageName,
    required String path,
  }) = AnalysisOptionsPackageRef;

  const factory AnalysisOptionsRef.local(String path) = AnalysisOptionsLocalRef;

  factory AnalysisOptionsRef.fromJson(String json) {
    final uri = Uri.parse(json);
    if (uri.isScheme('package')) {
      return AnalysisOptionsRef.package(
        packageName: uri.pathSegments[0],
        path: posix.joinAll(uri.pathSegments.skip(1)),
      );
    } else {
      return AnalysisOptionsRef.local(uri.path);
    }
  }

  String toJson() => switch (this) {
    AnalysisOptionsPackageRef(:final packageName, :final path) =>
      'package:$packageName/$path',
    AnalysisOptionsLocalRef(:final path) => path,
  };

  @override
  String toString() => toJson();
}
