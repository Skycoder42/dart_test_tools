import 'dart:io';

import 'package:pub_semver/pub_semver.dart';
import 'package:pubspec_parse/pubspec_parse.dart';

import '../tools/github.dart';
import 'pub_wrapper.dart';
import 'sdk_iterator.dart';

class Updater {
  final bool flutterCompat;
  final bool bumpVersion;
  final String? reportPath;

  IOSink? _reportSink;

  Updater({
    required this.flutterCompat,
    required this.bumpVersion,
    required this.reportPath,
  });

  Future<void> call(Directory targetDirectory) async {
    if (reportPath case final String path) {
      _reportSink = File(path).openWrite();
    }

    final pub = await PubWrapper.create(
      targetDirectory,
      forceFlutter: flutterCompat,
    );

    await _updateSdks(pub);

    if (bumpVersion) {
      await _bumpVersion(pub);
    }
    await _updateDependencies(pub);
    await _updateAnalyzerPlugins(pub);

    if (bumpVersion) {
      await _releaseVersion(pub);
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
      await _updateSdk(
        name,
        pub,
        pubspec,
        'flutter',
        flutterVersion,
        useGreaterEquals: true,
      );
    });
  }

  Future<void> _updateSdk(
    String name,
    PubWrapper pub,
    Pubspec pubspec,
    String sdk,
    Version? version, {
    bool useGreaterEquals = false,
  }) async {
    if (version == null || !pubspec.environment.containsKey(sdk)) {
      Github.logDebug('Skipping $name for $sdk - No version configured');
      return;
    }

    final minVersion = Version(version.major, version.minor, 0);
    final constraint = useGreaterEquals
        ? VersionRange(min: minVersion, includeMin: true)
        : VersionConstraint.compatibleWith(minVersion);
    await pub.pubspecEdit(
      (editor) => editor.update(['environment', sdk], constraint.toString()),
    );
    final message = 'Settings $sdk version for $name to $constraint';
    _reportSink?.writeln('- $message');
    Github.logInfo(message);

    if (pubspec.workspace case null || []
        when bumpVersion && pub.hasChangelog) {
      await pub.cider([
        'log',
        'changed',
        'Updated min $sdk version to $constraint',
      ]);
    }
  }

  Future<void> _updateDependencies(PubWrapper pub) async {
    final needsFlutterTest = flutterCompat && !await pub.dependsOnFlutterTest();
    if (needsFlutterTest) {
      await pub.addFlutterTest();
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

    if (needsFlutterTest) {
      await pub.removeFlutterTest();
      await pub.upgrade();
    }
  }

  Future<void> _updateAnalyzerPlugins(PubWrapper pub) async {
    _reportSink?.writeln('### Analyzer Plugin Updates');
    final sdkIterator = SdkIterator(pub);
    await sdkIterator.iterate((name, pub, _, _) async {
      final plugins = await pub.analysisOptionsPlugins();
      if (plugins.isEmpty) {
        return;
      }

      final pubspec = await pub.pubspec();
      await pub.analysisOptionsEdit((editor) {
        for (final MapEntry(key: plugin, value: currentConstraint)
            in plugins.entries) {
          final dependency =
              pubspec.dependencies[plugin] ?? pubspec.devDependencies[plugin];
          if (dependency is! HostedDependency) {
            throw Exception(
              'Analyzer plugin $plugin is declared in the '
              'analysis_options.yaml of $name but is not a hosted '
              'dependency in its pubspec.yaml',
            );
          }

          final constraint = dependency.version.toString();
          if (constraint == currentConstraint) {
            continue;
          }

          editor.update(['plugins', plugin], constraint);
          final message = 'Updated plugin $plugin in $name to $constraint';
          _reportSink?.writeln('- $message');
          Github.logInfo(message);
        }
      });
    });
  }

  Future<void> _bumpVersion(PubWrapper pub) async {
    final sdkIterator = SdkIterator(pub);
    await sdkIterator.iterate((name, pub, _, _) async {
      final pubspec = await pub.pubspec();
      if (pubspec.workspace case List(isEmpty: false)) {
        Github.logDebug('Skipping workspace package: $name');
        return;
      }
      if (pubspec.version == null) {
        Github.logDebug('Skipping package without version: $name');
        return;
      }

      Github.logInfo('Bumping patch version of $name');
      await pub.cider(const ['bump', 'patch']);
      await pub.cider(const ['version-sync']);
    });
  }

  Future<void> _releaseVersion(PubWrapper pub) async {
    final sdkIterator = SdkIterator(pub);
    await sdkIterator.iterate((name, pub, _, _) async {
      final pubspec = await pub.pubspec();
      if (pubspec.workspace case List(isEmpty: false)) {
        Github.logDebug('Skipping workspace package: $name');
        return;
      }
      final canBumpVersion = pubspec.version != null;
      final canLogChangelog = pub.hasChangelog;
      if (!canBumpVersion && !canLogChangelog) {
        Github.logDebug('Skipping package $name - nothing to release');
        return;
      }

      Github.logInfo('Creating update for $name');
      if (canLogChangelog) {
        await pub.cider(const ['log', 'changed', 'Updated dependencies']);
      }
      if (canBumpVersion && canLogChangelog) {
        await pub.cider(const ['release']);
      }
    });
  }
}
