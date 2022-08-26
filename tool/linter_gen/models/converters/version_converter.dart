import 'package:json_annotation/json_annotation.dart';
import 'package:pub_semver/pub_semver.dart';

class VersionConverter extends JsonConverter<Version, String> {
  const VersionConverter();

  @override
  Version fromJson(String json) => Version.parse(json);

  @override
  String toJson(Version version) => version.toString();
}
