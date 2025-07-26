import 'dart:io';

import 'package:pub_semver/pub_semver.dart';
import 'package:pubspec_parse/pubspec_parse.dart';

import '../tools/github.dart';
import 'pub_wrapper.dart';
import 'sdk_iterator.dart';

class Updater {
  static const _flutterTestPackageName = 'flutter_test';

  final bool bumpVersion;
  final String? reportPath;

  IOSink? _reportSink;

  Updater({required this.bumpVersion, required this.reportPath});

  Future<void> call(Directory targetDirectory) async {
    if (reportPath case final String path) {
      _reportSink = File(path).openWrite();
    }

    final pub = PubWrapper(targetDirectory, isFlutter: true);

    await _updateSdks(pub);

    await _updateDependencies(pub);

    if (bumpVersion) {
      await _bumpVersion(pub);
    }

    await _reportSink?.flush();
    await _reportSink?.close();
    _reportSink = null;
  }

  Future<void> _updateSdks(PubWrapper pub) async {
    _reportSink?.writeln('### SDK Updates');
    final sdkIterator = SdkIterator(pub);
    await sdkIterator.iterate((name, pub, dartVersion, flutterVersion) async {
      final pubspec = await pub.pubspec();
      await _updateSdk(name, pub, pubspec, 'sdk', dartVersion);
      await _updateSdk(name, pub, pubspec, 'flutter', flutterVersion);
    });
  }

  Future<void> _updateSdk(
    String name,
    PubWrapper pub,
    Pubspec pubspec,
    String sdk,
    Version? version,
  ) async {
    if (version == null || !pubspec.environment.containsKey(sdk)) {
      Github.logDebug('Skipping $name for $sdk - No version configured');
      return;
    }

    final constraint = VersionConstraint.compatibleWith(
      Version(version.major, version.minor, 0),
    );
    await pub.pubspecEdit(
      (editor) => editor.update(['environment', sdk], constraint.toString()),
    );
    final message = 'Settings $sdk version for $name to $constraint';
    _reportSink?.writeln('- $message');
    Github.logInfo(message);

    if (bumpVersion) {
      await pub.globalRun('dart_test_tools:cider', [
        'log',
        'changed',
        'Updated min $sdk version to $constraint',
      ]);
    }
  }

  Future<void> _updateDependencies(PubWrapper pub) async {
    final hasFlutterTest = await _hasFlutterTest(pub);
    if (!hasFlutterTest) {
      await pub.add(
        _flutterTestPackageName,
        dev: true,
        config: {'sdk': 'flutter'},
      );
    }

    final changes = pub.upgradeMajor();
    _reportSink
      ?..writeln('### Dependency Updates')
      ..writeln('```');
    await for (final line in changes) {
      _reportSink?.writeln(line);
      print(line);
    }
    _reportSink?.writeln('```');

    if (!hasFlutterTest) {
      await pub.remove(_flutterTestPackageName);
      await pub.upgrade();
    }
  }

  Future<bool> _hasFlutterTest(PubWrapper pub) async {
    final deps = await pub.deps();
    return deps.packages.any((p) => p.name == _flutterTestPackageName);
  }

  Future<void> _bumpVersion(PubWrapper pub) async {
    final sdkIterator = SdkIterator(pub);
    await sdkIterator.iterate((name, pub, _, _) async {
      final pubspec = await pub.pubspec();
      if (pubspec.workspace case List(isEmpty: false)) {
        // Do not run for workspace packages
        Github.logDebug('Skipping workspace package $name');
        return;
      }

      Github.logInfo('Bumping patch version of $name');
      await pub.globalRun('dart_test_tools:cider', [
        'log',
        'changed',
        'Updated dependencies',
      ]);
      await pub.globalRun('dart_test_tools:cider', ['bump', 'patch']);
      await pub.globalRun('dart_test_tools:cider', ['version-sync']);
      await pub.globalRun('dart_test_tools:cider', ['release']);
    });
  }
}
