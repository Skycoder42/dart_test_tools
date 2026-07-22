import 'dart:convert';
import 'dart:io';

import 'package:meta/meta.dart';
import 'package:pubspec_parse/pubspec_parse.dart';
import 'package:yaml/yaml.dart';
import 'package:yaml_edit/yaml_edit.dart';

import '../tools/github.dart';
import '../tools/io.dart';
import 'models/dependency_source.dart';
import 'models/pub/deps/dependencies.dart';
import 'models/pub/outdated/outdated_info.dart';
import 'models/pub/workspace/workspaces.dart';

@internal
class PubWrapper {
  static const flutterTestPackageName = 'flutter_test';

  final Directory workingDirectory;
  final bool isFlutter;

  String get _executable => isFlutter ? 'flutter' : 'dart';

  PubWrapper(this.workingDirectory, {required this.isFlutter});

  static Future<PubWrapper> create(
    Directory workingDirectory, {
    bool forceFlutter = false,
  }) async => PubWrapper(
    workingDirectory,
    isFlutter: forceFlutter || await _isFlutterProject(workingDirectory),
  );

  Future<Pubspec> pubspec() async {
    final file = workingDirectory.subFile('pubspec.yaml');
    final yaml = await file.readAsString();
    return Pubspec.parse(yaml, sourceUrl: file.uri);
  }

  bool get hasChangelog =>
      workingDirectory.subFile('CHANGELOG.md').existsSync();

  Future<void> pubspecEdit(void Function(YamlEditor editor) edit) async {
    final file = workingDirectory.subFile('pubspec.yaml');
    final yaml = await file.readAsString();
    final editor = YamlEditor(yaml);
    edit(editor);
    if (editor.edits.isNotEmpty) {
      await file.writeAsString(editor.toString(), flush: true);
    }
  }

  /// Returns the analyzer plugins declared in `analysis_options.yaml` that use
  /// a plain version constraint string, keyed by plugin name.
  ///
  /// Declarations that are not simple version constraints (e.g. `path:` maps or
  /// `false` to disable a plugin) are omitted.
  Future<Map<String, String>> analysisOptionsPlugins() async {
    final file = workingDirectory.subFile('analysis_options.yaml');
    if (!file.existsSync()) {
      return const {};
    }

    final yaml = loadYaml(await file.readAsString());
    if (yaml is! YamlMap) {
      return const {};
    }

    final plugins = yaml['plugins'];
    if (plugins is! YamlMap) {
      return const {};
    }

    return {
      for (final MapEntry(:key, :value) in plugins.entries)
        if (value is String) key as String: value,
    };
  }

  Future<void> analysisOptionsEdit(
    void Function(YamlEditor editor) edit,
  ) async {
    final file = workingDirectory.subFile('analysis_options.yaml');
    final yaml = await file.readAsString();
    final editor = YamlEditor(yaml);
    edit(editor);
    if (editor.edits.isNotEmpty) {
      await file.writeAsString(editor.toString(), flush: true);
    }
  }

  Future<void> upgrade() async => await _exec('upgrade');

  Stream<String> upgradeMajor() =>
      _execLines('upgrade', ['--major-versions', '--tighten']);

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

  Future<void> addFlutterTest() =>
      add(flutterTestPackageName, dev: true, config: const {'sdk': 'flutter'});

  Future<void> removeFlutterTest() => remove(flutterTestPackageName);

  Future<bool> dependsOnFlutterTest() async {
    final deps = await this.deps();
    return deps.packages.any((p) => p.name == flutterTestPackageName);
  }

  Future<Dependencies> deps() async =>
      await _execJson('deps').map(Dependencies.fromJson).single;

  Future<OutdatedInfo> outdated() async => await _execJson('outdated', [
    '--show-all',
    '--dev-dependencies',
  ]).map(OutdatedInfo.fromJson).single;

  Future<Workspaces> workspaceList() async =>
      await _execJson('workspace', ['list']).map(Workspaces.fromJson).single;

  Future<void> cider(List<String> commands) => Github.exec(
    'cider',
    commands,
    workingDirectory: workingDirectory,
    runInShell: Platform.isWindows,
  );

  Future<void> _exec(String command, [List<String> args = const []]) =>
      Github.exec(
        _executable,
        ['pub', command, ...args],
        workingDirectory: workingDirectory,
        runInShell: Platform.isWindows,
      );

  Stream<String> _execLines(String command, [List<String> args = const []]) =>
      Github.execLines(
        _executable,
        ['pub', command, ...args],
        workingDirectory: workingDirectory,
        runInShell: Platform.isWindows,
      );

  Stream<Map<String, dynamic>> _execJson(
    String command, [
    List<String> args = const [],
  ]) => _execLines(command, [
    ...args,
    '--json',
  ]).transform(json.decoder).cast<Map<String, dynamic>>();

  static Future<bool> _isFlutterProject(Directory workingDirectory) async {
    final wrapper = PubWrapper(workingDirectory, isFlutter: false);
    final dependencies = await wrapper.deps();
    return dependencies.packages.any(
      (p) => p.source == DependencySource.sdk && p.name.contains('flutter'),
    );
  }
}
