import 'dart:io';

import 'package:collection/collection.dart';
import 'package:pub_semver/pub_semver.dart';

import 'pub_wrapper.dart';

typedef SdkCallback =
    Future<void> Function(
      String name,
      PubWrapper pub,
      Version? dartVersion,
      Version? flutterVersion,
    );

class SdkIterator {
  final PubWrapper pub;

  SdkIterator(this.pub);

  Future<void> iterate(SdkCallback callback) async {
    final deps = await pub.deps();
    final dartVersion = deps.sdks
        .singleWhereOrNull((s) => s.name == 'Dart')
        ?.version;
    final flutterVersion = deps.sdks
        .singleWhereOrNull((s) => s.name == 'Flutter')
        ?.version;

    final workspaces = await PubWrapper(
      pub.workingDirectory,
      isFlutter: false,
    ).workspaceList();

    for (final info in workspaces.packages) {
      await callback(
        info.name,
        PubWrapper(Directory(info.path), isFlutter: pub.isFlutter),
        dartVersion,
        flutterVersion,
      );
    }
  }
}
