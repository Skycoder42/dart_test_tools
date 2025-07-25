import 'package:freezed_annotation/freezed_annotation.dart';

part 'workspace_info.freezed.dart';
part 'workspace_info.g.dart';

@freezed
sealed class WorkspaceInfo with _$WorkspaceInfo {
  const factory WorkspaceInfo({required String name, required String path}) =
      _WorkspaceInfo;

  factory WorkspaceInfo.fromJson(Map<String, dynamic> json) =>
      _$WorkspaceInfoFromJson(json);
}
