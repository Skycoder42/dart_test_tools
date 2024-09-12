import 'dart:io';

import 'package:crypto/crypto.dart';

import '../tools/github.dart';
import '../tools/io.dart';
import 'cask_options.dart';
import 'cask_options_loader.dart';

class CaskGenerator {
  final CaskOptionsLoader _caskOptionsLoader;

  const CaskGenerator([
    this._caskOptionsLoader = const CaskOptionsLoader(),
  ]);

  Future<void> call({
    required Directory inDir,
    required Directory outDir,
  }) async {
    final options = await _caskOptionsLoader.load(inDir);
    final config = await _buildCasksConfig(options);

    final caskName = _getCaskName(options);
    await Github.env.setOutput('caskName', caskName);

    await _writeCaskScript(outDir, options, caskName, config);
  }

  Future<List<Map<String, dynamic>>> _buildCasksConfig(
    CaskOptions options,
  ) async =>
      [
        {
          'version': options.pubspec.version,
          'sha256': await _getDmgSha256Sum(options),
        },
        {
          'url': options.options.downloadUrl,
          'name': options.appInfo.productName,
          'desc': options.pubspec.description,
          'homepage': options.pubspec.homepage,
        },
        {
          'depends_on macos:': '>= ${options.options.minMacosVersion}',
        },
        {
          'app': '${options.appInfo.productName}.app',
        },
        if (options.options.zap case final List<dynamic> zap
            when zap.isNotEmpty)
          {
            'zap trash:': zap,
          }
        else if (options.options.zap == null)
          {
            'zap trash:': [
              '~/Library/Containers/${options.appInfo.productBundleIdentifier}',
            ],
          },
      ];

  Future<String> _getDmgSha256Sum(CaskOptions options) async {
    final client = HttpClient();
    final tmpDir = await Directory.systemTemp.createTemp();
    try {
      final realUrl = Uri.parse(
        options.options.downloadUrl.replaceAll(
          '#{version}',
          options.pubspec.version!.toString(),
        ),
      );

      final dmgFile = await client.download(
        tmpDir,
        realUrl,
        withSignature: false,
      );

      return await dmgFile
          .openRead()
          .transform(sha256)
          .map((d) => d.toString())
          .single;
    } finally {
      await tmpDir.delete(recursive: true);
      client.close(force: true);
    }
  }

  Future<void> _writeCaskScript(
    Directory outDir,
    CaskOptions options,
    String caskName,
    List<Map<String, dynamic>> config,
  ) async {
    final casksDir = await outDir.subDir('Casks').create();
    final caskFile = casksDir.subFile('$caskName.rb');
    final caskSink = caskFile.openWrite();
    try {
      caskSink.writeln('cask "$caskName" do');
      var isFirst = true;
      for (final section in config) {
        if (isFirst) {
          isFirst = false;
        } else {
          caskSink.writeln();
        }

        for (final MapEntry(key: key, value: value) in section.entries) {
          caskSink
            ..write('  ')
            ..write(key)
            ..write(' ');
          switch (value) {
            case null:
              throw Exception('Missing cask configuration value: $key');
            case List<dynamic>():
              caskSink.writeln('[');
              for (final line in value) {
                caskSink
                  ..write('    "')
                  ..write(line)
                  ..writeln('"');
              }
              caskSink.writeln('  ]');
            default:
              caskSink
                ..write('"')
                ..write(value)
                ..writeln('"');
          }
        }
      }
      caskSink.writeln('end');
    } finally {
      await caskSink.close();
    }
  }

  String _getCaskName(CaskOptions options) {
    if (options.options.caskName case final String caskName) {
      return caskName;
    }

    return options.pubspec.name
        .toLowerCase()
        .replaceAll(RegExp('[^a-z0-9-]'), '-');
  }
}
