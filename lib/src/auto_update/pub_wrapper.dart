import 'dart:convert';
import 'dart:io';

import 'package:meta/meta.dart';
import 'package:pubspec_parse/pubspec_parse.dart';
import 'package:yaml_edit/yaml_edit.dart';

import '../tools/github.dart';
import '../tools/io.dart';
import 'models/dependency_source.dart';
import 'models/pub/deps/dependencies.dart';
import 'models/pub/outdated/outdated_info.dart';
import 'models/pub/workspace/workspaces.dart';

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

  Future<Pubspec> pubspec() async {
    final file = workingDirectory.subFile('pubspec.yaml');
    final yaml = await file.readAsString();
    return Pubspec.parse(yaml, sourceUrl: file.uri);
  }

  Future<void> pubspecEdit(void Function(YamlEditor editor) edit) async {
    final file = workingDirectory.subFile('pubspec.yaml');
    final yaml = await file.readAsString();
    final editor = YamlEditor(yaml);
    edit(editor);
    if (editor.edits.isNotEmpty) {
      await file.writeAsString(editor.toString(), flush: true);
    }
  }

  Future<void> upgrade({
    bool majorVersions = false,
    bool tighten = false,
  }) async => await _exec('upgrade', [
    if (majorVersions) '--major-versions',
    if (tighten) '--tighten',
  ]);

  Future<void> downgrade() async => await _exec('downgrade');

  Future<void> add(
    String name, {
    bool dev = false,
    Map<String, dynamic>? config,
  }) async {
    final refBuilder = StringBuffer();
    if (dev) {
      refBuilder.write('dev:');
    }
    refBuilder.write(name);
    if (config != null) {
      refBuilder
        ..write(':')
        ..write(json.encode(config));
    }

    await _exec('add', [refBuilder.toString()]);
  }

  Future<void> remove(String name) async {
    await _exec('remove', [name]);
  }

  Future<Dependencies> deps() async =>
      await _execJson('deps').map(Dependencies.fromJson).single;

  Future<OutdatedInfo> outdated() async => await _execJson('outdated', [
    '--show-all',
    '--dev-dependencies',
  ]).map(OutdatedInfo.fromJson).single;

  Future<Workspaces> workspaceList() async =>
      await _execJson('workspace', ['list']).map(Workspaces.fromJson).single;

  Future<void> globalRun(String name, [List<String> args = const []]) async =>
      await _exec('global', ['run', name, ...args]);

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
