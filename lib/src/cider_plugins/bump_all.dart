import 'dart:async';

import 'package:args/args.dart';
import 'package:cider/cider.dart';
import 'package:dart_test_tools/src/cider_plugins/cider_plugin.dart';

class BumpAllPlugin implements CiderPlugin {
  @override
  void call(Cider cider) {
    cider.addCommand(_BumpAllCommand(), _bumpAllHandler);
  }

  FutureOr<int?> _bumpAllHandler(ArgResults args, V Function<V>([String]) get) {
    return null;
  }
}

class _BumpAllCommand extends CiderCommand {
  _BumpAllCommand() : super('bump-all', 'bump-all');
}
