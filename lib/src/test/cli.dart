import 'dart:io';

import 'package:args/args.dart';

import 'mode.dart';
import 'target.dart';

class Cli {
  static late final _parser = ArgParser(allowTrailingOptions: false)
    ..addMultiOption(
      'platforms',
      abbr: 'p',
      allowed: TargetX.values,
      defaultsTo: TargetX.values,
    )
    ..addMultiOption(
      'modes',
      abbr: 'm',
      allowed: ModeX.values,
      defaultsTo: ModeX.values,
    )
    ..addFlag('coverage', abbr: 'c')
    ..addFlag('html-coverage', abbr: 'h')
    ..addFlag('open-coverage', abbr: 'o')
    ..addMultiOption(
      'coverage-exclude',
      abbr: 'x',
    )
    ..addFlag(
      'help',
      abbr: '?',
      negatable: false,
    );

  final ArgResults _args;

  late final modes = ModeX.parse(_args['modes'] as List<String>).toList();
  late final platforms = TargetX.parse(_args['platforms'] as List<String>);
  late final bool coverage = _args['coverage'] as bool;
  late final bool htmlCoverage = coverage && (_args['html-coverage'] as bool);
  late final bool openCoverage =
      htmlCoverage && (_args['open-coverage'] as bool);
  late final coverageExclude = _args['coverage-exclude'] as List<String>;

  Cli._(this._args);

  static Cli? parse(Iterable<String> arguments) {
    final args = _parser.parse(arguments);

    if (args['help'] as bool) {
      stdout.writeln(_parser.usage);
      return null;
    }

    return Cli._(args);
  }
}
