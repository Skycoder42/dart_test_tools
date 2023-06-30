import 'dart:io';

import 'package:dart_test_tools/src/aur/aur_options.dart';
import 'package:dart_test_tools/src/aur/aur_options_loader.dart';
import 'package:dart_test_tools/src/aur/pkgbuild.dart';
import 'package:path/path.dart';
import 'package:pub_semver/pub_semver.dart';
import 'package:pubspec_parse/pubspec_parse.dart';

class PkgBuildGenerator {
  static const _supportedArchs = ['x86_64', 'i686', 'armv7h', 'aarch64'];
  static const _supportedDebArchs = ['amd64'];

  final AurOptionsLoader aurOptionsLoader;

  const PkgBuildGenerator({
    this.aurOptionsLoader = const AurOptionsLoader(),
  });

  Future<void> generatePkgbuild({
    required Directory sourceDirectory,
    required Directory aurDirectory,
    bool makedebMode = false,
  }) async {
    final aurOptions = await aurOptionsLoader.loadAurOptions(sourceDirectory);
    final changelogFile = await aurOptionsLoader.findChangelog(sourceDirectory);
    final licenseFile = await aurOptionsLoader.findLicense(sourceDirectory);
    final installFile = aurOptionsLoader.findByName(
      sourceDirectory,
      aurOptions.aurOptions.install,
    );

    await aurDirectory.create(recursive: true);

    final pkgBuildFile = File.fromUri(aurDirectory.uri.resolve('PKGBUILD'));
    await pkgBuildFile.writeAsString(_pkgbuildTemplate(
      options: aurOptions,
      licenseFileName: _fileName(licenseFile),
      installFileName: _fileName(installFile),
      changelogFileName: _fileName(changelogFile),
      makedebMode: makedebMode,
    ));
    _printFileName(pkgBuildFile);

    if (installFile != null) {
      await _copyToDir(installFile, aurDirectory);
    }

    if (changelogFile != null) {
      await _copyToDir(changelogFile, aurDirectory);
    }
  }

  String? _fileName(File? file) => file != null ? basename(file.path) : null;

  Future<void> _copyToDir(File file, Directory aurDirectory) async {
    final copiedFile = await file.copy(
      aurDirectory.uri.resolve(basename(file.path)).toFilePath(),
    );
    _printFileName(copiedFile);
  }

  void _printFileName(File file) => print(_fileName(file));

  String _pkgbuildTemplate({
    required PubspecWithAur options,
    required String? licenseFileName,
    required String? installFileName,
    required String? changelogFileName,
    required bool makedebMode,
  }) {
    final version = options.pubspec.version;
    if (version == null) {
      throw Exception('pubspec version must not be null!');
    }

    final url =
        options.pubspec.homepage ?? options.pubspec.repository?.toString();
    final depends =
        (makedebMode ? options.aurOptions.makedeb?.depends : null) ??
            options.aurOptions.depends;
    final backup = (makedebMode ? options.aurOptions.makedeb?.backup : null) ??
        options.aurOptions.backup;

    final pkgBuild = Pkgbuild(
      maintainer: options.aurOptions.maintainer,
      properties: {
        'pkgname': PkgProperty(
          options.aurOptions.pkgname ?? options.pubspec.name,
        ),
        'pkgdesc': PkgProperty(options.pubspec.description),
        'pkgver': PkgProperty(version.toString().replaceAll('-', '_')),
        'pkgrel': PkgProperty(options.aurOptions.pkgrel),
        'epoch': PkgProperty(options.aurOptions.epoch),
        if (makedebMode)
          'arch': PkgProperty.literalList(_supportedDebArchs)
        else
          'arch': PkgProperty.literalList(_supportedArchs),
        'url': PkgProperty(url),
        'license': PkgProperty.literalList([options.aurOptions.license]),
        'depends': PkgProperty.literalList(
          depends,
          skipEmpty: false,
        ),
        'makedepends': _getDartDependency(options.pubspec),
        '_pkgdir': PkgProperty('${options.pubspec.name}-$version'),
        'source': _getSourceUrls(options.pubspec),
        'b2sums': PkgProperty.literalList(const ['PLACEHOLDER']),
        'install': PkgProperty(installFileName),
        'changelog': PkgProperty(changelogFileName),
        'backup': PkgProperty.literalList(backup),
        'options': PkgProperty.literalList(const ['!strip']),
        if (makedebMode)
          // Workaround for https://github.com/makedeb/makedeb/issues/214
          // See https://github.com/makedeb/makedeb/blob/alpha/src/main.sh#L130
          'extensions': PkgProperty.literalList(const ['zipman']),
      },
      functions: {
        'prepare': const PkgFunction([
          'dart pub get',
        ]),
        'build': PkgFunction(_getBuildSteps(options).toList()),
        'check': PkgFunction([
          'dart analyze --no-fatal-warnings',
          options.aurOptions.testArgs == null
              ? 'dart test'
              : 'dart test ${options.aurOptions.testArgs}',
        ]),
        'package': PkgFunction(
          _getInstallSteps(options, licenseFileName, makedebMode).toList(),
        ),
      },
    );

    return pkgBuild.encode();
  }

  PkgProperty _getDartDependency(Pubspec pubspec) {
    final dependencies = <String>[];

    final dartSdkConstraints = pubspec.environment?['sdk'];
    if (dartSdkConstraints is VersionRange) {
      final minVersion = dartSdkConstraints.min;
      if (minVersion != null) {
        final strippedMin =
            minVersion.isPreRelease ? minVersion.nextPatch : minVersion;
        if (dartSdkConstraints.includeMin) {
          dependencies.add('dart>=$strippedMin');
        } else {
          dependencies.add('dart>$strippedMin');
        }
      }

      final maxVersion = dartSdkConstraints.max;
      if (maxVersion != null) {
        final strippedMax =
            maxVersion.isPreRelease ? maxVersion.nextPatch : maxVersion;
        if (dartSdkConstraints.includeMax) {
          dependencies.add('dart<=$strippedMax');
        } else {
          dependencies.add('dart<$strippedMax');
        }
      }
    }

    if (dependencies.isEmpty) {
      dependencies.add('dart');
    }

    return PkgProperty.literalList(dependencies);
  }

  PkgProperty _getSourceUrls(Pubspec pubspec) {
    final baseRepo = pubspec.repository ?? pubspec.homepage;
    if (baseRepo == null) {
      throw Exception('Either repository or homepage must be set!');
    }
    final baseRepoString = baseRepo.toString();

    final repoUri = Uri.parse(
      baseRepoString.endsWith('/') ? baseRepoString : '$baseRepoString/',
    ).resolveUri(Uri(path: 'archive/refs/tags/v${pubspec.version}.tar.gz'));

    return PkgProperty.list([
      PkgProperty.interpolate('\$_pkgdir.tar.gz::$repoUri'),
    ]);
  }

  Iterable<String> _getBuildSteps(PubspecWithAur options) sync* {
    if (options.executables.isEmpty) {
      throw Exception('Must define at least one executable!');
    }

    if (options.pubspec.devDependencies.containsKey('build_runner')) {
      yield 'dart run build_runner build --delete-conflicting-outputs --release';
    }

    yield* options.executables.entries.map(
      (entry) => 'dart compile exe '
          "-o 'bin/${entry.key}' "
          "-S 'bin/${entry.key}.symbols' "
          "'bin/${entry.value ?? entry.key}.dart'",
    );
  }

  Iterable<String> _getInstallSteps(
    PubspecWithAur options,
    String? licenseFileName,
    bool makedebMode,
  ) sync* {
    if (options.executables.isEmpty) {
      throw Exception('Must define at least one executable!');
    }

    yield* options.executables.entries.map(
      (entry) => 'install -D -m755 '
          "'bin/${entry.key}' "
          "\"\$pkgdir/usr/bin/\"'${entry.key}'",
    );

    final installFiles =
        (makedebMode ? options.aurOptions.makedeb?.files : null) ??
            options.aurOptions.files;

    for (final install in installFiles) {
      yield "install -D -m${install.permissions} '${install.source}' "
          '"\$pkgdir${install.target}"';
    }

    if (licenseFileName != null) {
      yield 'install -D -m644 '
          "'$licenseFileName' "
          "\"\$pkgdir/usr/share/licenses/\$pkgname/\"'$licenseFileName'";
    }
  }
}
