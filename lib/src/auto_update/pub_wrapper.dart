import 'dart:convert';
import 'dart:io';

import 'package:meta/meta.dart';

import '../tools/github.dart';
import 'models/dependency_source.dart';
import 'models/pub/deps/dependencies.dart';
import 'models/pub/outdated/outdated_info.dart';

@internal
class PubWrapper {
  final Directory workingDirectory;
  final bool isFlutter;

  String get _executable => isFlutter ? 'flutter' : 'dart';

  PubWrapper(this.workingDirectory, {required this.isFlutter});

  static Future<PubWrapper> create(Directory workingDirectory) async =>
      PubWrapper(
        workingDirectory,
        isFlutter: await _isFlutterProject(workingDirectory),
      );

  Future<void> upgrade() async => await _exec('upgrade');

  Future<void> downgrade() async => await _exec('downgrade');

  Future<Dependencies> deps() async =>
      await _execJson('deps').map(Dependencies.fromJson).single;

  Future<OutdatedInfo> outdated() async => await _execJson('outdated', [
    '--show-all',
    '--dev-dependencies',
  ]).map(OutdatedInfo.fromJson).single;

  Future<void> _exec(String command, [List<String> args = const []]) =>
      Github.exec(
        _executable,
        ['pub', command, ...args],
        workingDirectory: workingDirectory,
        runInShell: Platform.isWindows,
      );

  Stream<Map<String, dynamic>> _execJson(
    String command, [
    List<String> args = const [],
  ]) => Github.execLines(
    _executable,
    ['pub', command, ...args, '--json'],
    workingDirectory: workingDirectory,
    runInShell: Platform.isWindows,
  ).transform(json.decoder).cast<Map<String, dynamic>>();

  static Future<bool> _isFlutterProject(Directory workingDirectory) async {
    final wrapper = PubWrapper(workingDirectory, isFlutter: false);
    final dependencies = await wrapper.deps();
    return dependencies.packages.any(
      (p) => p.source == DependencySource.sdk && p.name.contains('flutter'),
    );
  }
}
