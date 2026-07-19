import 'dart:io';

import 'package:args/args.dart';
import 'package:dart_test_tools/nfpm.dart';

Future<void> main(List<String> rawArgs) async {
  final parser =
      ArgParser(
          usageLineLength: stdout.hasTerminal ? stdout.terminalColumns : null,
        )
        ..addOption(
          'input',
          abbr: 'i',
          defaultsTo: Directory.current.path,
          valueHelp: 'directory',
          help:
              'The source <directory> of the dart package that should be '
              'packaged.',
        )
        ..addOption(
          'nfpm',
          abbr: 'n',
          valueHelp: 'file',
          help: 'The template nfpm.yaml <file>. Defaults to <input>/nfpm.yaml.',
        )
        ..addOption(
          'output',
          abbr: 'o',
          valueHelp: 'directory',
          help:
              'The target <directory> where the generated nfpm.yaml and '
              'changelog.yaml are written. Defaults to <input>/build/nfpm.',
        )
        ..addOption(
          'bundle-root',
          abbr: 'b',
          valueHelp: 'directory',
          help:
              'The <directory> of the built bundle. Written as the src of the '
              'generated tree content entry. This option is required.',
        )
        ..addFlag('help', abbr: 'h', negatable: false, help: 'Show this help.');

  try {
    final args = parser.parse(rawArgs);

    if (args['help'] as bool) {
      stdout.writeln(parser.usage);
      return;
    }

    final bundleRoot = args['bundle-root'] as String?;
    if (bundleRoot == null) {
      throw const FormatException('Missing required option --bundle-root.');
    }

    final inputDir = Directory(args['input'] as String);

    // Resolve relative paths against the input directory (absolute paths are
    // returned unchanged), so all inputs share the same anchor.
    String resolveInput(String path) =>
        inputDir.uri.resolveUri(Uri.file(path)).toFilePath();

    final templatePath = resolveInput((args['nfpm'] as String?) ?? 'nfpm.yaml');
    final outputPath = resolveInput(
      (args['output'] as String?) ?? 'build/nfpm',
    );

    const generator = NfpmGenerator();
    await generator.generate(
      inputDirectory: inputDir,
      templateFile: File(templatePath),
      outputDirectory: Directory(outputPath),
      bundleRoot: Directory(resolveInput(bundleRoot)),
    );
  } on FormatException catch (e) {
    stderr
      ..writeln('Error: ${e.message}\n')
      ..writeln('Usage:')
      ..writeln(parser.usage);
    exitCode = 3;
  }
}
