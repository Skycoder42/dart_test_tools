@internal
library;

import 'dart:io';

import 'package:freezed_annotation/freezed_annotation.dart';

import 'auto_export_config.dart';

part 'unresolved_export.freezed.dart';

@freezed
sealed class UnresolvedExport with _$UnresolvedExport {
  const factory UnresolvedExport.glob(FileSystemEntity fse) =
      UnresolvedGlobExport;
  const factory UnresolvedExport.single(SingleExportDefinition export) =
      UnresolvedSimpleExport;

  const UnresolvedExport._();

  Uri get uri => switch (this) {
    UnresolvedGlobExport(:final fse) => fse.uri,
    UnresolvedSimpleExport(:final export) => export.uri,
  };
}
