import 'dart:async';
import 'dart:io';

import 'package:args/args.dart';
import 'package:cider/cider.dart';
import 'package:dart_test_tools/src/cider_plugins/cider_plugin.dart';
import 'package:pubspec_parse/pubspec_parse.dart';

class VersionSyncPlugin implements CiderPlugin {
  const VersionSyncPlugin();

  @override
  void call(Cider cider) {
    cider.addCommand(_BumpAllCommand(), _versionSyncHandler);
  }

  Future<int> _versionSyncHandler(
    ArgResults args,
    V Function<V>([String]) get,
  ) async {
    final stdout = get<Stdout>();
    final stderr = get<Stdout>('stderr');
    final rootDir = get<Directory>('root');

    final pubspecFile = File.fromUri(rootDir.uri.resolve('pubspec.yaml'));
    final pubspec = Pubspec.parse(
      await pubspecFile.readAsString(),
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

    return 0;
  }

  Future<void> _updateAndroid(
    Stdout stdout,
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
      RegExp(r"^version '.*'$", multiLine: true),
      (m) => "version '${pubspec.version}'",
    );
    stdout.writeln('Synced version with android');
  }

  Future<void> _updateDarwin(
    Stdout stdout,
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
      RegExp(r"^(\s*)s.version(\s*)= '.*'$", multiLine: true),
      (m) => "${m[1]}s.version${m[2]}= '${pubspec.version}'",
    );
    stdout.writeln('Synced version with $os');
  }

  Future<void> _replaceInFileMapped(
    File file,
    Pattern pattern,
    String Function(Match) replace,
  ) async {
    final content = await file.readAsString();
    final updatedContent = content.replaceFirstMapped(pattern, replace);
    await file.writeAsString(updatedContent);
  }
}

class _BumpAllCommand extends CiderCommand {
  _BumpAllCommand()
      : super(
          'version-sync',
          'Updates the native package versions of flutter plugins '
              'to match the pubspec.yaml version',
        );
}
