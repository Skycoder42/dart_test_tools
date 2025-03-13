import 'dart:io';

import 'package:freezed_annotation/freezed_annotation.dart';

part 'repo_metadata.freezed.dart';

@freezed
sealed class IconInfo with _$IconInfo {
  const factory IconInfo({
    required String iconName,
    required Uri iconUrl,
    required File iconFile,
  }) = _IconInfo;
}

@freezed
sealed class GpgInfo with _$GpgInfo {
  const factory GpgInfo({required String keyId, required File publicKeyFile}) =
      _GpgInfo;
}

@freezed
sealed class RepoMetadata with _$RepoMetadata {
  const factory RepoMetadata({
    required String name,
    required String id,
    required Uri url,
    required GpgInfo gpgInfo,
    @Default('main') String branch,
    String? title,
    String? summary,
    String? description,
    Uri? homepage,
    IconInfo? icon,
  }) = _RepoMetadata;
}
