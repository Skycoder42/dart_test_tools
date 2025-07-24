import 'package:freezed_annotation/freezed_annotation.dart';

part 'executable_name.freezed.dart';

@Freezed(fromJson: false, toJson: false)
sealed class ExecutableName with _$ExecutableName {
  const factory ExecutableName.root(String name) = RootExecutableName;
  const factory ExecutableName.package(String package, String name) =
      PackageExecutableName;

  factory ExecutableName.fromJson(String json) {
    if (json.startsWith(':')) {
      return ExecutableName.root(json.substring(1));
    } else if (json.indexOf(':') case final int index when index >= 0) {
      return ExecutableName.package(
        json.substring(0, index),
        json.substring(index + 1),
      );
    } else {
      return ExecutableName.package(json, json);
    }
  }

  const ExecutableName._();

  String toJson() => switch (this) {
    RootExecutableName(:final name) => ':$name',
    PackageExecutableName(:final package, :final name) =>
      name == package ? name : '$package:$name',
  };

  @override
  String toString() => toJson();
}
