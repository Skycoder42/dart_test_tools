import 'dart:io';

import 'package:dart_test_tools/src/aur/aur_options.dart';
import 'package:dart_test_tools/src/aur/aur_options_loader.dart';
import 'package:dart_test_tools/src/aur/pkgbuild.dart';
import 'package:path/path.dart';
import 'package:pubspec_parse/pubspec_parse.dart';

class PkgBuildGenerator {
  static const _supportedArchs = ['x86_64'];
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
    final pkgBase = options.aurOptions.pkgname ?? options.pubspec.name;

    final pkgBuild = Pkgbuild(
      maintainer: options.aurOptions.maintainer,
      properties: {
        'pkgbase': PkgProperty(pkgBase),
        'pkgname': PkgProperty.literalList([pkgBase, '$pkgBase-debug']),
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
        '_pkgdir': PkgProperty('${options.pubspec.name}-$version'),
        'source': _getSourceUrls(options.pubspec),
        'b2sums': PkgProperty.literalList(
          const ['PLACEHOLDER', 'PLACEHOLDER', 'PLACEHOLDER'],
          multiLine: true,
        ),
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
        'package_$pkgBase': PkgFunction(
          _getInstallSteps(options, licenseFileName, makedebMode).toList(),
        ),
        'package_$pkgBase-debug': PkgFunction(
          _getDebugInstallSteps(options, pkgBase).toList(),
        ),
      },
    );

    return pkgBuild.encode();
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

    final binariesBaseUri = Uri.parse(
      baseRepoString.endsWith('/') ? baseRepoString : '$baseRepoString/',
    ).resolveUri(Uri(path: 'releases/download/v${pubspec.version}/'));

    return PkgProperty.list(multiLine: true, [
      PkgProperty.interpolate('\$_pkgdir.tar.gz::$repoUri'),
      PkgProperty.interpolate(
        'bin.tar.xz::${binariesBaseUri.resolve('binaries-linux.tar.xz')}',
      ),
      PkgProperty.interpolate(
        'debug.tar.xz::${binariesBaseUri.resolve('binaries-linux-debug-symbols.tar.xz')}',
      ),
    ]);
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
      (entry) =>
          'install -D -m755 ' +
          (options.executables.length > 1
              ? "'../bin/${entry.key}' "
              : "'../${entry.key}' ") +
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

  Iterable<String> _getDebugInstallSteps(
    PubspecWithAur options,
    String pkgBase,
  ) sync* {
    if (options.executables.isEmpty) {
      throw Exception('Must define at least one executable!');
    }

    yield* options.executables.entries.map(
      (entry) =>
          'install -D -m644 ' +
          (options.executables.length > 1
              ? "'../debug/${entry.key}.sym' "
              : "'../${entry.key}.sym' ") +
          "\"\$pkgdir/usr/lib/debug/usr/bin/\"'${entry.key}'.sym",
    );

    yield 'find . -exec '
        'install -D -m644 "{}" "\$pkgdir/usr/src/debug/\$pkgname/{}" \\;';
  }
}
