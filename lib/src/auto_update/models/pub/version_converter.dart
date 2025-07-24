import 'package:json_annotation/json_annotation.dart';
import 'package:meta/meta_meta.dart';
import 'package:pub_semver/pub_semver.dart';

@Target({TargetKind.classType, TargetKind.constructor})
class VersionConverter implements JsonConverter<Version, String> {
  const VersionConverter();

  @override
  Version fromJson(String json) => Version.parse(json);

  @override
  String toJson(Version object) => object.toString();
}
