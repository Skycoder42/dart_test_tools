import 'package:freezed_annotation/freezed_annotation.dart';

import 'workspace_info.dart';

part 'workspaces.freezed.dart';
part 'workspaces.g.dart';

@freezed
sealed class Workspaces with _$Workspaces {
  const factory Workspaces({required List<WorkspaceInfo> packages}) =
      _Workspaces;

  factory Workspaces.fromJson(Map<String, dynamic> json) =>
      _$WorkspacesFromJson(json);
}
