import 'dart:async';
import 'dart:io';

import 'package:cider/src/project.dart';
import 'package:pubspec_parse/pubspec_parse.dart';
import 'package:yaml/yaml.dart';

import 'package:cider/src/cli/command/cider_command.dart';
import 'package:cider/src/cli/find_project_root.dart';
import 'package:cider/src/cli/channel.dart';

class VersionSyncCommand extends CiderCommand {
  VersionSyncCommand(super.printer);

  @override
  String get name => 'version-sync';

  @override
  String get description =>
      'Updates the native package versions of flutter plugins '
      'to match the pubspec.yaml version';

  @override
  Future<int> exec(Project project) async {
    final stdout = printer.out;
    final stderr = printer.err;
    final rootDir = switch (globalResults!['project-root']) {
      String path => Directory(path),
      _ => findProjectRoot(Directory.current)
    };

    final pubspecFile = File.fromUri(rootDir.uri.resolve('pubspec.yaml'));
    final pubspecYaml = await pubspecFile.readAsString();
    final pubspec = Pubspec.parse(
      pubspecYaml,
      sourceUrl: pubspecFile.uri,
    );

    final version = pubspec.version;
    if (version == null) {
      stderr.writeln('pubspec.yaml has no version set!');
      return 1;
    }
    stdout.writeln('Syncing version $version to native packages...');

    await _updateAndroid(stdout, rootDir, pubspec);
    await _updateDarwin(stdout, rootDir, pubspec, 'ios');
    await _updateDarwin(stdout, rootDir, pubspec, 'macos');
    await _updateConfigured(
      stdout,
      rootDir,
      pubspec,
      pubspecYaml,
      pubspecFile.uri,
    );

    return 0;
  }

  Future<void> _updateAndroid(
    Channel stdout,
    Directory rootDir,
    Pubspec pubspec,
  ) async {
    final buildGradle = File.fromUri(
      rootDir.uri.resolve('android/build.gradle'),
    );
    if (!buildGradle.existsSync()) {
      stdout.writeln('Skipping android');
      return;
    }

    await _replaceInFileMapped(
      buildGradle,
      r"^version '.*'$",
      (m) => "version '${pubspec.version}'",
    );
    stdout.writeln('Synced version with android');
  }

  Future<void> _updateDarwin(
    Channel stdout,
    Directory rootDir,
    Pubspec pubspec,
    String os,
  ) async {
    final buildGradle = File.fromUri(
      rootDir.uri.resolve('$os/${pubspec.name}.podspec'),
    );
    if (!buildGradle.existsSync()) {
      stdout.writeln('Skipping $os');
      return;
    }

    await _replaceInFileMapped(
      buildGradle,
      r"^(\s*)s.version(\s*)= '.*'$",
      (m) => "${m[1]}s.version${m[2]}= '${pubspec.version}'",
    );
    stdout.writeln('Synced version with $os');
  }

  Future<void> _updateConfigured(
    Channel stdout,
    Directory rootDir,
    Pubspec pubspec,
    String pubspecYaml,
    Uri pubspecUrl,
  ) async {
    final yaml = loadYaml(pubspecYaml, sourceUrl: pubspecUrl) as YamlMap?;
    final cider = yaml?['cider'] as YamlMap?;
    final versionSync = cider?['version_sync'] as YamlMap?;
    if (versionSync == null) {
      return;
    }

    for (final entry in versionSync.entries) {
      final path = entry.key as String;
      final config = entry.value as YamlMap;

      final file = File.fromUri(rootDir.uri.resolve(path));
      if (!file.existsSync()) {
        stdout.writeln('Skipping $path');
        continue;
      }

      await _replaceInFileMapped(
        file,
        config['pattern'] as String,
        (m) => (config['replacement'] as String)
            .replaceAll('%{version}', pubspec.version!.toString()),
      );

      stdout.writeln('Synced version with $path');
    }
  }

  Future<void> _replaceInFileMapped(
    File file,
    String pattern,
    String Function(Match) replace,
  ) async {
    final content = await file.readAsString();
    final updatedContent = content.replaceFirstMapped(
      RegExp(pattern, multiLine: true),
      replace,
    );
    await file.writeAsString(updatedContent);
  }
}
