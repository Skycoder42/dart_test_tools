@internal
library;

import 'dart:io';

import 'package:freezed_annotation/freezed_annotation.dart';

import 'auto_export_config.dart';

part 'unresolved_export.freezed.dart';

@freezed
sealed class UnresolvedExport with _$UnresolvedExport {
  const factory glob(FileSystemEntity fse) = UnresolvedGlobExport;
  const factory single(SingleExportDefinition export) = UnresolvedSimpleExport;

  const new _();

  Uri get uri => switch (this) {
    UnresolvedGlobExport(:final fse) => fse.uri,
    UnresolvedSimpleExport(:final export) => export.uri,
  };
}
