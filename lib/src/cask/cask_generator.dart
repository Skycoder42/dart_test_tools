import 'dart:convert';
import 'dart:io';

import 'package:crypto/crypto.dart';

import '../tools/github.dart';
import '../tools/io.dart';
import 'cask_options.dart';
import 'cask_options_loader.dart';

/// A raw Ruby literal that is written to the cask script verbatim, without
/// being wrapped in quotes (e.g. a symbol like `:catalina`).
class const _CaskLiteral(final String value);

class const CaskGenerator([
  final CaskOptionsLoader _caskOptionsLoader = const CaskOptionsLoader(),
]) {
  Future<void> call({
    required Directory inDir,
    required Directory outDir,
  }) async {
    final options = await _caskOptionsLoader.load(inDir);
    final config = await _buildCasksConfig(inDir, options);

    final caskName = _getCaskName(options);
    await Github.env.setOutput('caskName', caskName);

    await _writeCaskScript(outDir, options, caskName, config);
  }

  Future<List<Map<String, dynamic>>> _buildCasksConfig(
    Directory inDir,
    CaskOptions options,
  ) async => [
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
      'depends_on macos:': _CaskLiteral(
        options.options.minMacosVersion ?? await _getMinMacosVersion(inDir),
      ),
    },
    {'app': '${options.appInfo.productName}.app'},
    if (options.options.zap case final List<dynamic> zap when zap.isNotEmpty)
      {'zap trash:': zap}
    else if (options.options.zap == null)
      {
        'zap trash:': [
          '~/Library/Containers/${options.appInfo.productBundleIdentifier}',
        ],
      },
  ];

  /// Reads MACOSX_DEPLOYMENT_TARGET of the macOS project via xcodebuild and
  /// converts it to the matching homebrew macOS symbol (e.g. `:monterey`).
  Future<String> _getMinMacosVersion(Directory inDir) async {
    final result = await Process.run('xcodebuild', [
      '-project',
      inDir.subDir('macos').subDir('Runner.xcodeproj').path,
      '-scheme',
      'Runner',
      '-configuration',
      'Release',
      '-showBuildSettings',
      '-json',
    ]);
    if (result.exitCode != 0) {
      throw Exception(
        'Failed to read build settings via xcodebuild '
        '(exit code ${result.exitCode}): ${result.stderr}',
      );
    }

    final settings = jsonDecode(result.stdout as String) as List<dynamic>;
    final deploymentTarget = settings
        .cast<Map<String, dynamic>>()
        .map(
          (e) =>
              (e['buildSettings']
                  as Map<String, dynamic>)['MACOSX_DEPLOYMENT_TARGET'],
        )
        .whereType<String>()
        .firstOrNull;
    if (deploymentTarget == null) {
      throw Exception(
        'MACOSX_DEPLOYMENT_TARGET is not set in the macOS project',
      );
    }

    return await _macosVersionToSymbol(deploymentTarget);
  }

  /// Asks homebrew itself for the symbol of the given macOS version, so no
  /// version names have to be maintained here.
  Future<String> _macosVersionToSymbol(String deploymentTarget) async {
    if (!RegExp(r'^\d+(\.\d+){0,2}$').hasMatch(deploymentTarget)) {
      throw Exception('Invalid macOS deployment target: $deploymentTarget');
    }

    final result = await Process.run('brew', [
      'ruby',
      '-e',
      'puts MacOSVersion.new("$deploymentTarget").to_sym',
    ]);
    if (result.exitCode != 0) {
      throw Exception(
        'Failed to resolve macOS version $deploymentTarget via homebrew '
        '(exit code ${result.exitCode}): ${result.stderr}',
      );
    }

    final symbol = (result.stdout as String).trim();
    if (symbol.isEmpty || symbol == 'dunno') {
      throw Exception(
        'Homebrew does not know a macOS release for deployment target '
        '$deploymentTarget (too old or too new for the installed homebrew). '
        'Set cask.minMacosVersion in the pubspec.yaml explicitly.',
      );
    }
    return ':$symbol';
  }

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

        for (final MapEntry(:key, :value) in section.entries) {
          caskSink
            ..write('  ')
            ..write(key)
            ..write(' ');
          switch (value) {
            case null:
              throw Exception('Missing cask configuration value: $key');
            case _CaskLiteral(:final value):
              caskSink.writeln(value);
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

    return options.pubspec.name.toLowerCase().replaceAll(
      RegExp('[^a-z0-9-]'),
      '-',
    );
  }
}
