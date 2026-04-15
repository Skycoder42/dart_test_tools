import 'dart:io';

import 'package:path/path.dart';

import 'aur_options.dart';
import 'aur_options_loader.dart';
import 'pkgbuild.dart';

class PkgBuildGenerator {
  static const _supportedArchs = ['x86_64'];
  static const _supportedDebArchs = ['amd64'];

  final AurOptionsLoader aurOptionsLoader;

  const PkgBuildGenerator({this.aurOptionsLoader = const AurOptionsLoader()});

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
    await pkgBuildFile.writeAsString(
      _pkgbuildTemplate(
        options: aurOptions,
        licenseFileName: _fileName(licenseFile),
        installFileName: _fileName(installFile),
        changelogFileName: _fileName(changelogFile),
        makedebMode: makedebMode,
      ),
    );
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
    final backup =
        (makedebMode ? options.aurOptions.makedeb?.backup : null) ??
        options.aurOptions.backup;
    final pkgName = options.aurOptions.pkgname ?? options.pubspec.name;
    final tagPrefix = options.aurOptions.tagPrefix;
    final pkgDirTagPrefix = tagPrefix == AurOptions.defaultTagPrefix
        ? ''
        : tagPrefix;
    final pkgDir = '$pkgName-$pkgDirTagPrefix$version'.replaceAll(
      RegExp(r'(?:\+|\/)'),
      '-',
    );

    final pkgBuild = Pkgbuild(
      maintainer: options.aurOptions.maintainer,
      properties: {
        'pkgname': PkgProperty(pkgName),
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
        'depends': PkgProperty.literalList(depends, skipEmpty: false),
        'source': _getSourceUrls(options),
        'b2sums': PkgProperty.literalList(
          List.filled(
            2 + options.aurOptions.extraSources.length,
            'PLACEHOLDER',
          ),
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
        if (options.aurOptions.sourcesDir case final String dir)
          '_pkgdir': PkgProperty('$pkgDir/$dir')
        else
          '_pkgdir': PkgProperty(pkgDir),
      },
      functions: {
        'package_$pkgName': PkgFunction(
          _getInstallSteps(options, licenseFileName, makedebMode).toList(),
        ),
      },
    );

    return pkgBuild.encode();
  }

  PkgProperty _getSourceUrls(PubspecWithAur options) {
    final baseRepoString =
        options.pubspec.repository?.toString() ?? options.pubspec.homepage;
    if (baseRepoString == null) {
      throw Exception('Either repository or homepage must be set!');
    }
    final baseRepo = Uri.parse(
      baseRepoString.endsWith('/') ? baseRepoString : '$baseRepoString/',
    );

    const sourcesPrefix = r'${pkgname}-${pkgver}';
    final encodedTag = Uri.encodeComponent(
      options.aurOptions.tagPrefix + options.pubspec.version.toString(),
    );
    final encodedBinaries = Uri.encodeComponent(
      '${options.archivePrefix}-linux.tar.xz',
    );

    final sourcesUri = baseRepo.resolve('archive/refs/tags/$encodedTag.tar.gz');
    final binariesUri = baseRepo.resolveUri(
      Uri(path: 'releases/download/$encodedTag/$encodedBinaries'),
    );

    return PkgProperty.list(multiLine: true, [
      PkgProperty.interpolate('$sourcesPrefix-sources.tar.gz::$sourcesUri'),
      PkgProperty.interpolate('$sourcesPrefix-linux.tar.xz::$binariesUri'),
      for (final extraSource in options.aurOptions.extraSources)
        PkgProperty.interpolate('${extraSource.name}::${extraSource.url}'),
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

    yield r'install -d "$pkgdir/opt/$pkgname"';
    yield 'cp -a \'${options.archivePrefix}/.\' "\$pkgdir/opt/\$pkgname/"';
    yield r'install -d "$pkgdir/usr/bin"';
    yield* options.executables.entries.map(
      (entry) =>
          'ln -s '
          "\"/opt/\$pkgname/bin/\"'${entry.key}' "
          "\"\$pkgdir/usr/bin/\"'${entry.key}'",
    );

    yield r'cd "$_pkgdir"';

    final installFiles =
        (makedebMode ? options.aurOptions.makedeb?.files : null) ??
        options.aurOptions.files;

    for (final install in installFiles) {
      if (install.recursive) {
        yield "pushd '${install.source}'";
        yield 'find . -type f -exec install -D -m${install.permissions} "{}" '
            '"\$pkgdir${install.target}/{}" \\;';
        yield 'popd';
      } else {
        yield "install -D -m${install.permissions} '${install.source}' "
            '"\$pkgdir${install.target}"';
      }
    }

    if (licenseFileName != null) {
      yield 'install -D -m644 '
          "'$licenseFileName' "
          "\"\$pkgdir/usr/share/licenses/\$pkgname/\"'$licenseFileName'";
    }
  }
}
