import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:path/path.dart';

part 'analysis_options_ref.freezed.dart';

@freezed
class AnalysisOptionsRef with _$AnalysisOptionsRef {
  const AnalysisOptionsRef._();

  const factory AnalysisOptionsRef.package({
    required String packageName,
    required String path,
  }) = _Package;

  const factory AnalysisOptionsRef.local(String path) = _Local;

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

  String toJson() => when(
    package: (packageName, path) => 'package:$packageName/$path',
    local: (path) => path,
  );

  @override
  String toString() => toJson();
}
